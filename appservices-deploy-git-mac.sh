# https://docs.microsoft.com/en-us/azure/app-service/scripts/app-service-cli-deploy-github

# Azure CLI for Mac/Linux (only difference is use of envvars %username% vs $USER)
# ...and the file extension

# run commands in Terminal

# gitrepo=https://github.com/Azure-Samples/php-docs-hello-world
gitrepo=https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git

# transform userid to lowercase since some Azure resource names don't like uppercase
userid=$(echo "$USER" | awk '{print tolower(S0)}')

webappname="$userid$RANDOM"
rgname="$webappname-rg"
webappplan="$webappname-plan"

az group create --location westeurope --name "$rgname"
az appservice plan create --name "$webappplan" --resource-group "$rgname" --sku FREE
az webapp create --name "$webappname" --resource-group "$rgname" --plan "$webappplan"
az webapp deployment source config --name "$webappname" --resource-group "$rgname" --repo-url "$gitrepo" --branch master --manual-integration

az webapp deployment source show --name "$webappname" --resource-group "$rgname"

echo http://$webappname.azurewebsites.net 
# az group delete --name $rgname
