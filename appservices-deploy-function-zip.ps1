# https://docs.microsoft.com/en-us/azure/azure-functions/deployment-zip-push

$location="West Europe"
# transform userid to lowercase since some Azure resource names don't like uppercase
$userid=$env:USERNAME.tolower()
$FuncAppName="$userid$(Get-Random)"
$rgname="$FuncAppName-rg"
$storageAccount="$($FuncAppName)stg"
$FunctionName="HttpTriggerCSharp3"

# ---------------------------------------------------------------------------------
# create the resource group
# ---------------------------------------------------------------------------------
New-AzureRmResourceGroup -Name "$rgname" -Location "$location" -force

# ---------------------------------------------------------------------------------
# create a storage account needed for the Function App
# ---------------------------------------------------------------------------------
New-AzureRmStorageAccount -ResourceGroupName "$rgname" -AccountName "$storageAccount" -Location "$location" -SkuName "Standard_LRS"
$keys = Get-AzureRmStorageAccountKey -ResourceGroupName "$rgname" -AccountName "$storageAccount"
$storageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=' + $storageAccount + ';AccountKey=' + $keys[0].Value

# ---------------------------------------------------------------------------------
# create the Function App
# ---------------------------------------------------------------------------------
New-AzureRmResource -ResourceGroupName "$rgname" -ResourceType "Microsoft.Web/Sites" -ResourceName "$FuncAppName" -kind "functionapp" -Location "$location" -Properties @{} -force

# ---------------------------------------------------------------------------------
# Create the files and folders on the fly here that makes a Function App
# ---------------------------------------------------------------------------------
$path=$PSScriptRoot 
if ( $path -eq "" ) { $path=$(get-location).Path }

# create subdirs
mkdir "$FuncAppName"
mkdir "$FuncAppName\$FunctionName"

# copy template run.csx into subdir
copy "$path\run.csx" "$FuncAppName\$FunctionName\run.csx"

# create host.json
( @{} | ConvertTo-json -Depth 10) > "$FuncAppName\host.json"  

# create local.settings.json
$propsL = @{
    IsEncrypted = $false
    Values = @{
      FUNCTIONS_EXTENSION_VERSION = "~1"
      ScmType = "None"
      WEBSITE_AUTH_ENABLED = $false
      AzureWebJobsDashboard = $storageAccountConnectionString
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING = $storageAccountConnectionString
      WEBSITE_CONTENTSHARE = $storageaccount
      WEBSITE_SITE_NAME = $FuncAppName
      WEBSITE_SLOT_NAME = "Production"
      AzureWebJobsStorage = $storageAccountConnectionString
    }
}
($propsL | ConvertTo-json -Depth 10) > "$FuncAppName\local.settings.json"  

# create function.json
$propsF = @{ 
        bindings = @(
            @{
                authLevel= "function"
                type = "httpTrigger"
                direction = "in"
                webHookType = ""
                name = "req"
                methods = @( "get", "post" )
            }
            @{
                type = "http"
                direction = "out"
                name = "`$return"
            }
        )
}
($propsF | ConvertTo-json -Depth 10) > "$FuncAppName\$FunctionName\function.json"

# ---------------------------------------------------------------------------------
# zip the code into a zip file that we can deploy
# ---------------------------------------------------------------------------------
Add-Type -Assembly System.IO.Compression.FileSystem
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
[System.IO.Compression.ZipFile]::CreateFromDirectory("$Path\$FuncAppName", "$path\$FuncAppname.zip", $compressionLevel, $False)

# ---------------------------------------------------------------------------------
# Deploy the zip file
# ---------------------------------------------------------------------------------
$apiUrl = "https://$FuncAppName.scm.azurewebsites.net/api/zipdeploy"
$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName "$rgname" -ResourceType "Microsoft.Web/sites/config" -ResourceName "$FuncAppName/publishingcredentials" -Action list -ApiVersion "2015-08-01" -Force
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword)))

Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent "powershell/1.0" -Method POST -InFile "$path\$FuncAppname.zip" -ContentType "multipart/form-data"

