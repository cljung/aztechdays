#/bin/bash

echoSection() {
    echo "#---------------------------------------------------------------------------"
    echo $1
    echo "#---------------------------------------------------------------------------"
}
waitMessage() {
    read -n 1 -s -r -p "$@";echo
}
waitMessage "Have you done az_login? It will fail misserably otherwise. Ctrl+C to exit now"
# get public ip addr
_PIP=$(curl ipinfo.io/ip)   
# transform userid to lowercase since some Azure resource names don't like uppercase
userid=$(echo "$USER" | awk '{print tolower($0)}')
#---------------------------------------------------------------------------
echoSection "Step1 - build container app locally"
# https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-app
#---------------------------------------------------------------------------

git clone https://github.com/Azure-Samples/azure-voting-app-redis.git
cd azure-voting-app-redis
docker-compose up -d        # takes time
docker images
docker ps

echo "Browse to http://$_PIP/:8080 to the container app running on the Azure VM"
waitMessage "Continue?"

docker-compose stop
docker-compose down

# cd ..
#---------------------------------------------------------------------------
echoSection "Step2 - Deploy container to Container Registry in Azure"
waitMessage "Continue?"
# https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-prepare-acr
#---------------------------------------------------------------------------

RGNAME="$userid-aks-rg"
az group create --name $RGNAME --location westeurope
ACRNAME=$USER"aksacr"
az acr create --resource-group $RGNAME --name $ACRNAME --sku Basic
az acr login --name $ACRNAME
# docker images
ACRLOGINSERVER=$(az acr list --resource-group $RGNAME --query "[].{acrLoginServer:loginServer}" --output tsv)
# alt: az acr show --resource-group $RGNAME --name $ACRNAME
docker tag azure-vote-front $ACRLOGINSERVER/azure-vote-front:v1
docker images
docker push $ACRLOGINSERVER/azure-vote-front:v1    #  takes time

# next two are optional - just listing what we pushed
waitMessage "Continue?"
az acr repository list --name $ACRNAME --output table
az acr repository show-tags --name $ACRNAME --repository azure-vote-front --output table

#---------------------------------------------------------------------------
echoSection "Step3 - Deploy Kubernetes cluster in Azure"
waitMessage "Continue?"
# https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-cluster
#---------------------------------------------------------------------------

az provider register -n Microsoft.ContainerService
AKSCLUSTERNAME=$userid"aks01"
az aks create --resource-group $RGNAME --name $AKSCLUSTERNAME --node-count 1 --generate-ssh-keys  # takes time
az aks get-credentials --resource-group $RGNAME --name $AKSCLUSTERNAME

kubectl get nodes
CLIENT_ID=$(az aks show --resource-group $RGNAME --name $AKSCLUSTERNAME --query "servicePrincipalProfile.clientId" --output tsv)
ACR_ID=$(az acr show --name $ACRNAME --resource-group $RGNAME --query "id" --output tsv)
az role assignment create --assignee $CLIENT_ID --role Reader --scope $ACR_ID

#---------------------------------------------------------------------------
echoSection "Step4 - Deploy container app to Kubernetes cluster in Azure"
waitMessage "Continue?"
# https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-deploy-application
#---------------------------------------------------------------------------

ACRLOGINSERVER=$(az acr list --resource-group $RGNAME --query "[].{acrLoginServer:loginServer}" --output tsv)
# replace "microsoft" with "server name" from above az acr list cmd in yaml-file
# either with text editor or the lovely bash command below
sed -i -e "s/microsoft/$ACRLOGINSERVER/g" ./azure-vote-all-in-one-redis.yaml

kubectl create -f azure-vote-all-in-one-redis.yaml
kubectl get service azure-vote-front --watch
# Once the EXTERNAL-IP address has changed from pending to an IP address, use CTRL-C to stop the kubectl watch process.
# browse to ip address

#---------------------------------------------------------------------------
echoSection "Step4b - Kubernetes Dashboard"
waitMessage "Continue?"

sudo apt-get install -y nginx
# get public ip
_PIP=$(curl ipinfo.io/ip)   
# create nginx config
echo "server {
    listen 8080;
    server_name $_PIP;

    location / {
        proxy_set_header        X-Forwarded-For \$remote_addr;
        proxy_set_header        Host \$http_host;
        proxy_pass              \"http://localhost:8001\";
    }
}" > k8sdashboard-nginx.conf
# symlink it
sudo ln -s $(realpath k8sdashboard-nginx.conf) /etc/nginx/sites-enabled/k8sdashboard-nginx.conf
# restart nginx
sudo service nginx restart
echo "Browse to http://$_PIP/ to view the Kubernetes Dashboard"

az aks browse --resource-group $RGNAME --name $AKSCLUSTERNAME

#---------------------------------------------------------------------------
echoSection "Step5 - Scale Cluster"
# https://docs.microsoft.com/en-us/azure/aks/tutorial-kubernetes-scale
#---------------------------------------------------------------------------

# az aks scale --resource-group=$RGNAME --name=$AKSCLUSTERNAME --node-count 2

# remove everything
# az group delete –-name $RGNAME

