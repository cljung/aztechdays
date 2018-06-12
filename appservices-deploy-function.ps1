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

$AppSettings = @{'AzureWebJobsDashboard' = $storageAccountConnectionString;
    'AzureWebJobsStorage' = $storageAccountConnectionString;
    'FUNCTIONS_EXTENSION_VERSION' = '~1';
    'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING' = $storageAccountConnectionString;
    'WEBSITE_CONTENTSHARE' = $storageAccount;
}
Set-AzureRMWebApp -Name "$FuncAppName" -ResourceGroupName "$rgname" -AppSettings $AppSettings

# ---------------------------------------------------------------------------------
# Deploy Function to the Function App
# ---------------------------------------------------------------------------------

$path=$PSScriptRoot # $(get-location).Path
$CodeFile = "run.csx"
$FileContent = "$(Get-Content -Path "$path\$CodeFile" -Raw)"

$props = @{ 
        config = @{
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
                    name = "$return"
                }
            )
        }
        files = @{
            $CodeFile = $FileContent
        }
        test_data = $TestData
    }

New-AzureRmResource -ResourceGroupName $rgname -ResourceType "Microsoft.Web/sites/functions" -ResourceName "$FuncAppName/$FunctionName" -PropertyObject $props -ApiVersion "2015-08-01" -Force

$props = @{ 
    config = @{
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
}


Add-Type -Assembly System.IO.Compression.FileSystem
$compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
[System.IO.Compression.ZipFile]::CreateFromDirectory("$Path\$FuncAppName", "$path\$FuncAppname.zip", $compressionLevel, $False)

$apiUrl = "https://$FuncAppName.scm.azurewebsites.net/api/zipdeploy"
$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName "$rgname" -ResourceType "Microsoft.Web/sites/config" -ResourceName "$FuncAppName/publishingcredentials" -Action list -ApiVersion "2015-08-01" -Force
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword)))

Invoke-RestMethod -Uri $apiUrl -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -UserAgent "powershell/1.0" -Method POST -InFile "$path\$FuncAppname.zip" -ContentType "multipart/form-data"


# Get-AzureRmResource -ResourceGroupName $rgname -ResourceType "Microsoft.Web/sites/functions" -ResourceName "$FuncAppName/$FunctionName" -ApiVersion "2015-08-01" 

# Get-AzureRMWebApp -Name "$FuncAppName" -ResourceGroupName "$rgname" 
# $webapp.SiteConfig.AppSettings