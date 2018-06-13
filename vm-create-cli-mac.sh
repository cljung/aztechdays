#/bin/bash

# transform userid to lowercase since some Azure resource names don't like uppercase
userid=$(echo "$USER" | awk '{print tolower($0)}')
vmname=$userid$RANDOM
rgname=$vmname-rg
# vmpwd=Pwdpwd$RANDOM$RANDOM!
echo -n "VM Password for user $userid:" & read -s vmpwd
_PIP=$(curl http://ipinfo.io/ip)

# create the RG
az group create --location westeurope --name "$rgname"

# create the VM
az vm create --resource-group "$rgname" --name "$vmname" --image "UbuntuLTS" --admin-username "$USER" --admin-password "$vmpwd" --use-unmanaged-disk --size Standard_D1_v2 --storage-account "$(echo $vmname)stg" --storage-sku "Standard_LRS"
  
# run the installation script to setup the VM
az vm extension set --resource-group "$rgname" --vm-name "$vmname" --name "customScript" --publisher "Microsoft.Azure.Extensions" --protected-settings '{"fileUris":["https://raw.githubusercontent.com/cljung/aztechdays/master/ubuntu-install-devtools.sh"],"commandToExecute":"./ubuntu-install-devtools.sh '$userid'"}'  

# open the firewall so we can browse to various things the demo needs
nsgname="$(echo $vmname)NSG"
az network nsg rule create --resource-group "$rgname" --nsg-name "$nsgname" --name "Port_80" --access allow --protocol Tcp --direction Inbound --priority 110 --source-address-prefix "$_PIP" --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80
az network nsg rule create --resource-group "$rgname" --nsg-name "$nsgname" --name "Port_8080" --access allow --protocol Tcp --direction Inbound --priority 120 --source-address-prefix "$_PIP" --source-port-range "*" --destination-address-prefix "*" --destination-port-range 8080

az network nsg rule list --resource-group "$rgname" --nsg-name "$nsgname"

# rem show VM's public ip address
az vm show -g $rgname -n $vmname -d --query "publicIps" -o tsv

# login to the VM and do the following to avoid always running docker with sudo
#
# chmod +x download-azure-container-script.sh
# ./download-azure-container-script.sh
#
# this will download the azure-container-services-tutorial.sh

echo "password: $vmpwd"
