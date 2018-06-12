rem https://docs.microsoft.com/en-us/azure/app-service/scripts/app-service-cli-deploy-github

rem Azure CLI for Windows (only difference is use of envvars %username% vs $USER)
rem ...and the file extension

rem run commands in Command Prompt or Powershell prompt

set gitrepo=https://github.com/Azure-Samples/php-docs-hello-world
rem set gitrepo=https://github.com/Azure-Samples/app-service-web-dotnet-get-started.git

set webappname=%username%%RANDOM%
set rgname=%webappname%-rg
set webappplan=%webappname%-plan

az group create --location westeurope --name %rgname%
az appservice plan create --name "%webappplan%" --resource-group "%rgname%" --sku FREE
az webapp create --name "%webappname%" --resource-group "%rgname%" --plan "%webappplan%"

az webapp deployment source config --name "%webappname%" --resource-group "%rgname%" --repo-url "%gitrepo%" --branch master --manual-integration

az webapp deployment source show --name "%webappname%" --resource-group "%rgname%"

start http://%webappname%.azurewebsites.net

rem az group delete --name %rgname%
