#/bin/bash

if [$# -eq 0]; then
    echo "syntax: appservices-deploy-ftp.sh resource-group-name webappname local-file(s)"
    exit
fi

rgname=$1
webappname=$2
TARGETDIR="$(dirname "$3")"
TARGETFILE="$(basename "$3")"

# get ftp url, userid/pwd from Azure AppService publishing profile
FTPURL=$(az webapp deployment list-publishing-profiles -g $rgname -n $webappname --query "[1].publishUrl" -o tsv)
FTPUID=$(az webapp deployment list-publishing-profiles -g $rgname -n $webappname --query "[1].userName" -o tsv)
FTPPWD=$(az webapp deployment list-publishing-profiles -g $rgname -n $webappname --query "[1].userPWD" -o tsv)

# parse ftp url into server name with lovely bash commands
FTPSERVER=$(echo $FTPURL | sed 's/ftp:\/\///' | cut -d '/' -f 1 | sed 's/"//')
len=$(echo $FTPSERVER | awk '{print length}')
len=$((len+7))
FTPDIR=$(echo $FTPURL | cut -c $len-99 | sed 's/"//')

echo "ftp upload $TARGETDIR/$TARGETFILE --> $FTPSERVER $webappname $FTPDIR"

# upload files via ftp to Azure AppServices
ftp -p -n $FTPSERVER << EOF

user "$FTPUID" "$FTPPWD"
cd $FTPDIR
lcd $TARGETDIR
binary
del $TARGETFILE
mput $TARGETFILE
quit

EOF
