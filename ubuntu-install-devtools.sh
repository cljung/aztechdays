#/bin/bash

echo $(date +"%F %T%z") "starting"

if [ -z "$1" ]; then
    DEVUSER=$USER
else
    DEVUSER=$1
fi

# if you run this Ubuntu in a VNet with your own DNS, the host cannot resolve itself
# and we need to give abit of help so the installation don't fail

# _PIP=$(curl ipinfo.io/ip)
# _IP=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
# echo "$(hostname) $_IP" | sudo tee -a /etc/hosts > /dev/null

echoSection() {
    echo "#---------------------------------------------------------------------------"
    echo $1
    echo "#---------------------------------------------------------------------------"
}
#---------------------------------------------------------------------------
echoSection "Installing Git" 
#---------------------------------------------------------------------------
sudo apt-get update && sudo apt-get install -y git-core

#---------------------------------------------------------------------------
echoSection "Installing Azure CLI" 
#---------------------------------------------------------------------------
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest
AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | \
     sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893     
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo apt-get install -y apt-transport-https
sudo apt-get update && sudo apt-get install azure-cli

#---------------------------------------------------------------------------
echoSection "Installing Docker" 
#---------------------------------------------------------------------------
# https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update && sudo apt-get install -y docker.io
# sudo docker run hello-world

echoSection "Fixing Docker group membership" 
# set so that your user can run docker w/o sudo. requires logoff/login after completion
sudo groupadd docker
sudo gpasswd -a $DEVUSER docker

echoSection "Installing Docker-Compose" 
# https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-16-04
# webpage has verion 1.18.0, but change to most recent version
sudo curl -L https://github.com/docker/compose/releases/download/1.21.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

#---------------------------------------------------------------------------
echoSection "Install kubectl for Kubernetes" 
#---------------------------------------------------------------------------
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list > /dev/null
sudo apt-get update && sudo apt-get install -y kubectl

#---------------------------------------------------------------------------
echoSection "Install other usefull stuff" 
#---------------------------------------------------------------------------
sudo apt-get install dos2unix

#---------------------------------------------------------------------------
echoSection "creating the Azure Containers download script"
#---------------------------------------------------------------------------
cat <<EOF > "/home/$userid/download-azure-container-script.sh"
wget https://raw.githubusercontent.com/cljung/aztechdays/master/azure-container-services-tutorial.sh
chmod +x azure-container-services-tutorial.sh
dos2unix azure-container-services-tutorial.sh
EOF

#---------------------------------------------------------------------------
echoSection "Verify by running git|az|docker|docker-compose|kubectl --version"
#---------------------------------------------------------------------------
echo $(date +"%F %T%z") "completed"
