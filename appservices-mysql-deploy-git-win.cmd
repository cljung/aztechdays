rem https://docs.microsoft.com/en-us/azure/app-service/scripts/app-service-cli-deploy-github

rem Azure CLI for Windows (only difference is use of envvars %username% vs $USER)
rem ...and the file extension

rem run commands in Command Prompt or Powershell prompt

rem ---------------------------------------------------------------------------------
rem Deploy AppService WebApp from github
rem ---------------------------------------------------------------------------------

set gitrepo=https://github.com/cljung/php-mysql-sample.git

set rgname=%username%%RANDOM%-rg
set webappname=%username%%RANDOM%
set webappplan=%webappname%-plan

az group create --location westeurope --name "%rgname%"
az appservice plan create --name "%webappplan%" --resource-group "%rgname%" --sku S1
az webapp create --name "%webappname%" --resource-group "%rgname%" --plan "%webappplan%"
az webapp deployment source config --name "%webappname%" --resource-group "%rgname%" --repo-url "%gitrepo%" --branch master --manual-integration

az webapp deployment source show --name "%webappname%" --resource-group "%rgname%"

rem ---------------------------------------------------------------------------------
rem deploy MySQL
rem ---------------------------------------------------------------------------------

rem -- make sure %USERNAME% is lower case or change %USERNAME% by hand to something else in lo case
set SERVERNAME="%USERNAME%-mysqlsrv01"
set DBAUID=dba01
set DBAPWD="MySqlDb%RANDOM%"
set DBNAME=msgdb
set _PIP=94.234.43.79

az mysql server create -l westeurope -g "%rgname%" -n "%SERVERNAME%" -u "%DBAUID%" -p "%DBAPWD%" --sku-name B_Gen4_2 --ssl-enforcement Disabled --storage-size 51200 --version "5.7"
az mysql db create -g "%rgname%" -s "%SERVERNAME%" -n "%DBNAME%"

rem allow Azure to access it from the inside
az mysql server firewall-rule create -g "%rgname%" -s "%SERVERNAME%" -n AllowAllWindowsAzureIps --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

rem allow login from the PIP currently being used
az mysql server firewall-rule create -g "%rgname%" -s "%SERVERNAME%" -n allowall --start-ip-address %_PIP% --end-ip-address %_PIP%

az mysql server show -g %rgname% -n %SERVERNAME% --query "fullyQualifiedDomainName" -o tsv > %temp%\tempmysql.txt
set /p DBSRV=<%temp%\tempmysql.txt
del %temp%\tempmysql.txt

rem ---------------------------------------------------------------------------------
rem update WebApp's config to use MySQL
rem ---------------------------------------------------------------------------------
az webapp config appsettings set -g "%rgname%" -n "%webappname%" --settings "dbHost=%DBSRV%"
az webapp config appsettings set -g "%rgname%" -n "%webappname%" --settings "dbName=%DBNAME%"
az webapp config appsettings set -g "%rgname%" -n "%webappname%" --settings "dbUser=%DBAUID%@%SERVERNAME%"
az webapp config appsettings set -g "%rgname%" -n "%webappname%" --settings "dbPwd=%DBAPWD%"

rem ---------------------------------------------------------------------------------
rem launch webapp
rem ---------------------------------------------------------------------------------

start http://%webappname%.azurewebsites.net

rem ---------------------------------------------------------------------------------
rem remove everything
rem ---------------------------------------------------------------------------------

rem az group delete --name %rgname%
