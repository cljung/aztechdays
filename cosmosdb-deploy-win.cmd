set cdbname=%username%%RANDOM%
set rgname="%cdbname%-rg"
set cdbDbName=testdb
set cdbCollName=testcoll

rem browse to http://ipinfo.io/ip and grab your public ip address
set _PIP=130.180.44.70

az group create --location "westeurope" --name "%rgname%"

rem Create a DocumentDB API Cosmos DB account
az cosmosdb create -g "%rgname%" -n "%cdbname%" --kind "GlobalDocumentDB" --ip-range-filter "%_PIP%"

rem Create a database 
az cosmosdb database create -g "%rgname%" -n "%cdbname%" --db-name "%cdbDbName%"

rem Create a collection
az cosmosdb collection create -g "%rgname%" -n "%cdbname%" --db-name "%cdbDbName%" --collection-name "%cdbCollName%"

az cosmosdb show -g "%rgname%" -n "%cdbname%" -o tsv --query "documentEndpoint" > %temp%\cdbendpoint.txt
set /p CDBENDPOINT=<%temp%\cdbendpoint.txt

az cosmosdb list-keys -g "%rgname%" -n "%cdbname%" -o tsv --query "primaryMasterKey"> %temp%\cdbkey.txt
set /p CDBKEY=<%temp%\cdbkey.txt

del %temp%\cdbendpoint.txt
del %temp%\cdbkey.txt

echo AccountEndpoint=%CDBENDPOINT%;AccountKey=%CDBKEY%;
