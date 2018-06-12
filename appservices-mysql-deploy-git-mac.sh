#  https://docs.microsoft.com/en-us/azure/app-service/scripts/app-service-cli-deploy-github

# Azure CLI for Windows (only difference is use of envvars %username% vs $USER)
# ...and the file extension

# run commands in Command Prompt or Powershell prompt

# ---------------------------------------------------------------------------------
# Deploy AppService WebApp from github
# ---------------------------------------------------------------------------------

gitrepo=https://github.com/cljung/php-mysql-sample.git

webappname=$USER$RANDOM
rgname="$webappname-rg"
webappplan="$webappname-plan"

az group create --location westeurope --name "$rgname"
az appservice plan create --name "$webappplan" --resource-group "$rgname" --sku FREE
az webapp create --name "$webappname" --resource-group "$rgname" --plan "$webappplan"
az webapp deployment source config --name "$webappname" --resource-group "$rgname" --repo-url "$gitrepo" --branch master --manual-integration

# az webapp deployment source show --name "$webappname" --resource-group "$rgname"

# ---------------------------------------------------------------------------------
# deploy MySQL
# ---------------------------------------------------------------------------------

# transform userid to lowercase since some Azure resource names don't like uppercase
userid=$(echo "$USER" | awk '{print tolower($0)}')

SERVERNAME="$userid-mysqlsrv01"
DBAUID=dba01
DBAPWD="MySqlDb$RANDOM"
DBNAME=msgdb
_PIP=$(curl ipinfo.io/ip)   

az mysql server create -l westeurope -g "$rgname" -n "$SERVERNAME" -u "$DBAUID" -p "$DBAPWD" --sku-name B_Gen4_2 --ssl-enforcement Disabled --storage-size 51200 --version "5.7"
az mysql db create -g "$rgname" -s "$SERVERNAME" -n "$DBNAME"

# allow Azure to access it from the inside
az mysql server firewall-rule create -g "$rgname" -s "$SERVERNAME" -n AllowAllWindowsAzureIps --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# allow login from the PIP currently being used
az mysql server firewall-rule create -g "$rgname" -s "$SERVERNAME" -n allowall --start-ip-address $_PIP --end-ip-address $_PIP

DBSRV=$(az mysql server show -g $rgname -n $SERVERNAME --query "fullyQualifiedDomainName" -o tsv)
echo "FQDN of MySQL server $DBSRV"

# ---------------------------------------------------------------------------------
# update WebApp's config to use MySQL
# ---------------------------------------------------------------------------------
az webapp config appsettings set -g $rgname -n $webappname --settings "dbHost=$DBSRV"
az webapp config appsettings set -g $rgname -n $webappname --settings "dbName=$DBNAME"
az webapp config appsettings set -g $rgname -n $webappname --settings "dbUser=$DBAUID@$SERVERNAME"
az webapp config appsettings set -g $rgname -n $webappname --settings "dbPwd=$DBAPWD"

# ---------------------------------------------------------------------------------
# launch webapp
# ---------------------------------------------------------------------------------

echo "http://$webappname.azurewebsites.net"

# ---------------------------------------------------------------------------------
# remove everything
# ---------------------------------------------------------------------------------

# az group delete --name %rgname%
