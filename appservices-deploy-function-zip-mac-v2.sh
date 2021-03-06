# https://docs.microsoft.com/en-us/azure/azure-functions/functions-create-first-azure-function-azure-cli
# https://docs.microsoft.com/en-us/azure/azure-functions/scripts/functions-cli-create-serverless
# https://docs.microsoft.com/en-us/azure/azure-functions/deployment-zip-push

# Azure CLI for Mac/Linux (only difference is use of envvars %username% vs $USER)
# ...and the file extension

# run commands in Terminal

# this 2nd file updates an already existing Azure Functions

# transform userid to lowercase since some Azure resource names don't like uppercase
userid=$(echo "$USER" | awk '{print tolower($0)}')

funcappname=$1
rgname="$funcappname-rg"
functionname=HttpTriggerCSharp3
rgnamecdb=$2
cdbname=$3

STGCONNSTR=$(az storage account show-connection-string --name "$storageaccount" --resource-group "$rgname" -o tsv)

accountEndpoint=$(az cosmosdb show -g $rgnamecdb -n $cdbname -o tsv --query "documentEndpoint")
accountKey=$(az cosmosdb list-keys -g $rgnamecdb -n $cdbname -o tsv --query "primaryMasterKey")

CDBCONNSTR="AccountEndpoint=$accountEndpoint;AccountKey=$accountKey;"

# ---------------------------------------------------------------------------------
# Create the host.json, local.settings.json and function.json config files
# ---------------------------------------------------------------------------------

mkdir "$funcappname"
mkdir "$funcappname/$functionname"

echo {}>"$funcappname/host.json"

cat <<EOF > "$funcappname/local.settings.json"
{
   "IsEncrypted": false,
   "Values": {
     "FUNCTIONS_EXTENSION_VERSION": "~1",
    "ScmType": "None",
     "WEBSITE_AUTH_ENABLED": "False",
     "AzureWebJobsDashboard": "$STGCONNSTR",
     "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING": "$STGCONNSTR",
     "WEBSITE_CONTENTSHARE": "$storageaccount",
     "WEBSITE_SITE_NAME": "$funcappname",
     "WEBSITE_SLOT_NAME": "Production",
     "AzureWebJobsStorage": "$STGCONNSTR",
     "cosmosDb_connectString1": "$CDBCONNSTR"
   }
}
EOF

cat <<EOF >"$funcappname/$functionname/function.json"
{
"bindings": [
   {
     "direction": "in",
     "name": "req",
     "webHookType": "",
     "type": "httpTrigger",
     "authLevel": "function",
     "methods": [
       "get",
       "post"
     ]
   },
   {
     "name": "\$return",
     "direction": "out",
     "type": "http"
   },
   {
      "type": "documentDB",
      "name": "outputDocument",
      "databaseName": "outDatabase",
      "collectionName": "MyCollection",
      "createIfNotExists": false,
      "connection": "cosmosDb_connectString1",
      "direction": "out"
    }   
]
}
EOF

 
# copy our original run.csx into the function app folder
cp ./run-v2.csx "$funcappname/$functionname/run.csx"

# zip the folder to deply
cd ./$funcappname
pwd
zip -r "../$funcappname.zip" ./*  
cd ..
# ---------------------------------------------------------------------------------
# deploy zip file to Azure Functions App
# ---------------------------------------------------------------------------------
az functionapp deployment source config-zip  -g "$rgname" -n "$funcappname" --src "./$funcappname.zip"

# ---------------------------------------------------------------------------------
# remove everything
# ---------------------------------------------------------------------------------

# az group delete --name "$rgname"
