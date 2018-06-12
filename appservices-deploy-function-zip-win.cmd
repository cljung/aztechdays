rem https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function-azure-cli
rem https://docs.microsoft.com/en-us/azure/azure-functions/scripts/functions-cli-create-serverless
rem https://docs.microsoft.com/en-us/azure/azure-functions/deployment-zip-push

rem Azure CLI for Windows (only difference is use of envvars %username% vs $USER)
rem ...and the file extension

rem run commands in Command Prompt 

rem ---------------------------------------------------------------------------------
rem Create the resource group
rem ---------------------------------------------------------------------------------

set funcappname=%username%%RANDOM%
set rgname=%funcappname%-rg
set storageaccount=%funcappname%stg
set functionname=HttpTriggerCSharp3

rem ---------------------------------------------------------------------------------
rem Create the resource group
rem ---------------------------------------------------------------------------------
az group create --location "westeurope" -n "%rgname%"

rem ---------------------------------------------------------------------------------
rem Create the storage account needed for Azure Functions
rem ---------------------------------------------------------------------------------
az storage account create -n "%storageaccount%" --location "westeurope" -g "%rgname%" --sku "Standard_LRS"

az storage account show-connection-string --name "%storageaccount%" --resource-group "%rgname%" -o tsv > %temp%\tempstgconnstr.txt
set /p STGCONNSTR=<%temp%\tempstgconnstr.txt
del %temp%\tempstgconnstr.txt

rem ---------------------------------------------------------------------------------
rem Create the Azure Functions app
rem ---------------------------------------------------------------------------------
az functionapp create -n "%funcappname%" -s "%storageaccount%" -c "westeurope" -g "%rgname%"  rem -p "appservice plan create"

rem ---------------------------------------------------------------------------------
rem Create the host.json, local.settings.json and function.json config files
rem ---------------------------------------------------------------------------------

mkdir "%funcappname%"
mkdir "%funcappname%\%functionname%"

echo {}>"%funcappname%\host.json"

echo {>"%funcappname%\local.settings.json"
echo   "IsEncrypted": false,>>"%funcappname%\local.settings.json"
echo   "Values": {>>"%funcappname%\local.settings.json"
echo     "FUNCTIONS_EXTENSION_VERSION": "~1",>>"%funcappname%\local.settings.json"
echo     "ScmType": "None",>>"%funcappname%\local.settings.json"
echo     "WEBSITE_AUTH_ENABLED": "False",>>"%funcappname%\local.settings.json"
echo     "AzureWebJobsDashboard": "%STGCONNSTR%",>>"%funcappname%\local.settings.json"
echo     "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING": "%STGCONNSTR%",>>"%funcappname%\local.settings.json"
echo     "WEBSITE_CONTENTSHARE": "%storageaccount%",>>"%funcappname%\local.settings.json"
echo     "WEBSITE_SITE_NAME": "%funcappname%",>>"%funcappname%\local.settings.json"
echo     "WEBSITE_SLOT_NAME": "Production",>>"%funcappname%\local.settings.json"
echo     "AzureWebJobsStorage": "%STGCONNSTR%">>"%funcappname%\local.settings.json"
echo   }>>"%funcappname%\local.settings.json"
echo }>>"%funcappname%\local.settings.json"

echo {>"%funcappname%\%functionname%\function.json"
echo  "bindings": [>>"%funcappname%\%functionname%\function.json"
echo    {>>"%funcappname%\%functionname%\function.json"
echo      "direction": "in",>>"%funcappname%\%functionname%\function.json"
echo      "name": "req",>>"%funcappname%\%functionname%\function.json"
echo      "webHookType": "",>>"%funcappname%\%functionname%\function.json"
echo      "type": "httpTrigger",>>"%funcappname%\%functionname%\function.json"
echo      "authLevel": "function",>>"%funcappname%\%functionname%\function.json"
echo      "methods": [>>"%funcappname%\%functionname%\function.json"
echo        "get",>>"%funcappname%\%functionname%\function.json"
echo        "post">>"%funcappname%\%functionname%\function.json"
echo      ]>>"%funcappname%\%functionname%\function.json"
echo    },>>"%funcappname%\%functionname%\function.json"
echo    {>>"%funcappname%\%functionname%\function.json"
echo      "name": "$return",>>"%funcappname%\%functionname%\function.json"
echo      "direction": "out",>>"%funcappname%\%functionname%\function.json"
echo      "type": "http">>"%funcappname%\%functionname%\function.json"
echo    }>>"%funcappname%\%functionname%\function.json"
echo  ]>>"%funcappname%\%functionname%\function.json"
echo }>>"%funcappname%\%functionname%\function.json"

rem copy our original run.csx into the function app folder
copy .\run.csx "%funcappname%\%functionname%\""

rem ---------------------------------------------------------------------------------
rem Manually zip files 
rem ---------------------------------------------------------------------------------
echo "Pause here to zip the content of folder %funcappname% to a file named %funcappname%.zip"
echo "File host.json should be in the root of the zip file"
echo.
echo "When you press <Enter>, the zip file will be deployed to the Azure Function app"
pause

rem ---------------------------------------------------------------------------------
rem deploy zip file to Azure Functions App 
rem ---------------------------------------------------------------------------------
az functionapp deployment source config-zip  -g "%rgname%" -n "%funcappname%" --src ".\%funcappname%.zip"

rem ---------------------------------------------------------------------------------
rem remove everything
rem ---------------------------------------------------------------------------------

rem az group delete --name %rgname%
