# https://docs.microsoft.com/en-us/azure/app-service/scripts/app-service-powershell-deploy-github?toc=%2fpowershell%2fmodule%2ftoc.json

$gitrepo="https://github.com/cljung/php-mysql-sample.git"

$location="West Europe"
# transform userid to lowercase since some Azure resource names don't like uppercase
$userid=$env:USERNAME.tolower()
$webappname="$userid$(Get-Random)"
$rgname="$webappname-rg"
$webappplan="$webappname-plan"

# ---------------------------------------------------------------------------------
# Deploy AppService WebApp from github
# ---------------------------------------------------------------------------------

New-AzureRmResourceGroup -Name "$rgname" -Location "$location"

New-AzureRmAppServicePlan -Name $webappplan -Location $location -ResourceGroupName $rgname -Tier Free
New-AzureRmWebApp -Name $webappname -Location $location -AppServicePlan $webappplan -ResourceGroupName $rgname

$PropertiesObject = @{ repoUrl = "$gitrepo"; branch = "master"; isManualIntegration = "true"; }
Set-AzureRmResource -ResourceGroupName $rgname -ResourceName "$webappname/web" -ResourceType "Microsoft.Web/sites/sourcecontrols" -PropertyObject $PropertiesObject -ApiVersion "2015-08-01" -Force

# ---------------------------------------------------------------------------------
# deploy MySQL
# - there are no specific Azure Powershell CmdLets for MySQL (yet), so we have to do 
# - everything via low level via resource management
# ---------------------------------------------------------------------------------
$SERVERNAME="$userid-mysqlsrv01"
$DBAUID="dba01"
$DBAPWD="MySqlDb$(Get-Random)"
$DBNAME="msgdb"
# get our current public ip addr so we can set the NSG below to only allow access from that ip addr
$resp = Invoke-RestMethod "http://ipinfo.io"
$_PIP=$resp.ip

# register the ARM provider - one time operation
Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.DBforMySql"
$apiVersion="2017-12-01"
                        
# ---------------------------------------------------------------------------------
# create server
$json2='{"administratorLogin":"'+$DBAUID+'","administratorLoginPassword":"'+$DBAPWD+'","storageProfile":{"storageMB":51200,"backupRetentionDays":7,"geoRedundantBackup":"Disabled"},"version":"5.7","sslEnforcement":"Disabled","replicationRole":"None","primaryServerId":"","replicaCapacity":5}'
$prop2=($json2 | ConvertFrom-json)
$resSrv = New-AzureRmResource -Force -ResourceType "Microsoft.DBforMySQL/servers" -ResourceGroupName "$rgname" -ApiVersion $apiVersion -Location $location `
    -ResourceName "$SERVERNAME" -SkuObject @{name='B_Gen4_2'} -PropertyObject @prop2

# ---------------------------------------------------------------------------------
# create db
$propDB = ('{"charset":"latin1","collation":"latin1_swedish_ci"}' | ConvertFrom-json)        
New-AzureRmResource -Force -ResourceType "Microsoft.DBforMySQL/servers/databases" -ResourceGroupName "$rgname" -ApiVersion $apiVersion -Location $location `
    -ResourceName "$SERVERNAME/$DBNAME" -PropertyObject @propDB
        
# ---------------------------------------------------------------------------------
# set MySQL firweall to allow your current public ip address
$propFW = ('{"startIpAddress":"'+$_PIP+'","endIpAddress":"'+$_PIP+'"}' | ConvertFrom-json)        
New-AzureRmResource -Force -ResourceType "Microsoft.DBforMySQL/servers/firewallRules" -ResourceGroupName "$rgname" -ApiVersion $apiVersion -Location $location `
    -ResourceName "$SERVERNAME/AllowPip" -PropertyObject @propFW

# set MySQL firweall to allow internal Azure traffic
$propFW = ('{"startIpAddress":"0.0.0.0","endIpAddress":"0.0.0.0"}' | ConvertFrom-json)        
New-AzureRmResource -Force -ResourceType "Microsoft.DBforMySQL/servers/firewallRules" -ResourceGroupName "$rgname" -ApiVersion $apiVersion -Location $location `
    -ResourceName "$SERVERNAME/AllowAllWindowsAzureIps" -PropertyObject @propFW

# ---------------------------------------------------------------------------------
# update WebApp's config to use MySQL
# ---------------------------------------------------------------------------------
$newAppSettings = @{"dbHost"="$($resSrv.Properties.fullyQualifiedDomainName)";"dbName"="$DBNAME";"dbUser"="$DBAUID@$SERVERNAME";"dbPwd"="$DBAPWD"}

Set-AzureRmWebApp -ResourceGroupName "$rgName" -Name "$webappname" -AppSettings $newAppSettings
# ---------------------------------------------------------------------------------
# remove everything
# ---------------------------------------------------------------------------------

# Remove-AzureRmResourceGroup -Force -Name $rgname
