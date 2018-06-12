userid=$(echo "$USER" | awk '{print tolower($0)}')

cdbname="$userid$RANDOM"
rgname="$cdbname-rg"
cdbDbName=testdb
cdbCollName=testcoll
_PIP=$(curl http://ipinfo.io/ip)

az group create --location westeurope --name "$rgname"

# Create a DocumentDB API Cosmos DB account
az cosmosdb create -g "$rgname" -n "$cdbname" --kind "GlobalDocumentDB" --ip-range-filter $_PIP

# Create a database 
az cosmosdb database create -g $rgname -n $cdbname --db-name $cdbDbName 

# Create a collection
az cosmosdb collection create -g $rgname -n $cdbname --db-name $cdbDbName --collection-name $cdbCollName

accountEndpoint=$(az cosmosdb show -g $rgname -n $cdbname -o tsv --query "documentEndpoint")
accountKey=$(az cosmosdb list-keys -g $rgname -n $cdbname -o tsv --query "primaryMasterKey")

echo AccountEndpoint=$accountEndpoint\;AccountKey=$accountKey;
