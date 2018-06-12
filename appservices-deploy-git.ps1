# https://docs.microsoft.com/en-us/azure/app-service/scripts/app-service-powershell-deploy-github?toc=%2fpowershell%2fmodule%2ftoc.json

$gitrepo="https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git"

$location="West Europe"
# transform userid to lowercase since some Azure resource names don't like uppercase
$userid=$env:USERNAME.tolower()
$webappname="$userid$(Get-Random)"
$rgname="$webappname-rg"
$webappplan="$webappname-plan"

New-AzureRmResourceGroup -Name $rgname -Location $location

New-AzureRmAppServicePlan -Name $webappplan -Location $location -ResourceGroupName $rgname -Tier Free

New-AzureRmWebApp -Name $webappname -Location $location -AppServicePlan $webappplan -ResourceGroupName $rgname

$PropertiesObject = @{ repoUrl = "$gitrepo"; branch = "master"; isManualIntegration = "true"; }

Set-AzureRmResource -ResourceGroupName $rgname -ResourceName "$webappname/web" -ResourceType "Microsoft.Web/sites/sourcecontrols" -PropertyObject $PropertiesObject -ApiVersion "2015-08-01" -Force

# Get-AzureRmResource -ResourceGroupName $rgname -ResourceName "$webappname/web" -ResourceType "Microsoft.Web/sites/sourcecontrols" -ApiVersion "2015-08-01"

# Remove-AzureRmResourceGroup -Name $rgname -Force
