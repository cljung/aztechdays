# building on appservices-deploy-git-mac.sh

# deploy another website via:
# 1. set gitrepo var to 
#    gitrepo=https://github.com/cljung/php-mysql-sample.git
# 2. rerun appservices-deploy-git-mac.sh from step webappname=$USER$RANDOM

# transform userid to lowercase since some Azure resource names don't like uppercase
userid=$(echo "$USER" | awk '{print tolower(S0)}')

# creating a MySQL database
SERVERNAME="$serid-mysqlsrv01"
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
# if you want to install the MySQL client locally and connect to the db

sudo apt-get install mysql-client
mysql -u "$DBAUID@$SERVERNAME" -p"$DBAPWD" -h $DBSRV $DBNAME 

# update webapp appsettings with db details

az webapp config appsettings set -g $rgname -n $webappname --settings "dbHost=$DBSRV"
az webapp config appsettings set -g $rgname -n $webappname --settings "dbName=$DBNAME"
az webapp config appsettings set -g $rgname -n $webappname --settings "dbUser=$DBAUID@$SERVERNAME"
az webapp config appsettings set -g $rgname -n $webappname --settings "dbPwd=$DBAPWD"