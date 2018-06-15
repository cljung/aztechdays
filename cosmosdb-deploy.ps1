# https://docs.microsoft.com/en-us/azure/cosmos-db/scripts/secure-get-account-key-powershell

$location="West Europe"
# transform userid to lowercase since some Azure resource names don't like uppercase
$userid=$env:USERNAME.tolower()
$cdbname="$userid$(Get-Random)"
$rgname="$cdbname-rg"
$cdbDbName = "testdb"

$resp = Invoke-RestMethod "http://ipinfo.io"
$_PIP=$resp.ip

# Create the resource group
New-AzureRmResourceGroup -Name "$rgname" -Location "$location"

# Register-AzureRmResourceProvider -ProviderNamespace "Microsoft.DocumentDB"

# DB properties
$DBProperties = @{"databaseAccountOfferType"="Standard"; 
                  "consistencyPolicy"= @{
                                        "defaultConsistencyLevel"="BoundedStaleness";
                                        "maxIntervalInSeconds"="10"; 
                                        "maxStalenessPrefix"="200"
                                        };
                  "ipRangeFilter"="$_PIP,0.0.0.0,104.42.195.92,40.76.54.131,52.176.6.30,52.169.50.45,52.187.184.26";
                  }

# Create the database
New-AzureRmResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" `
                    -ResourceGroupName "$rgname" -Location "$location" -Name "$cdbname" `
                    -PropertyObject $DBProperties -Force

