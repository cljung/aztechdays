set vmname=%USERNAME%%RANDOM%
set rgname=%vmname%-rg
set vmpwd=Pwdpwd%RANDOM%!

az group create --location westeurope --name "%rgname%"

az vm create --resource-group "%rgname%" --name "%vmname%" --image "UbuntuLTS" --admin-username "%USERNAME%" --admin-password "%vmpwd%" --use-unmanaged-disk --size Standard_D1_v2 --storage-account "%vmname%stg" --storage-sku "Standard_LRS"

rem run a script inside the VM to complete the installation as we like it
az vm extension set --resource-group "%rgname%" --vm-name "%vmname%" --name "customScript" --publisher "Microsoft.Azure.Extensions" --protected-settings "{'fileUris': ['https://raw.githubusercontent.com/cljung/aztechdays/master/ubuntu-install-devtools.sh'],'commandToExecute': './ubuntu-install-devtools.sh %USERNAME%'}"

rem (AKS) the docker app running in the VM  
az network nsg rule create --resource-group "%rgname%" --nsg-name "%vmname%NSG" --name "Port_80" --access allow --protocol Tcp --direction Inbound --priority 110 --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range 80

rem (AKS)
az network nsg rule create --resource-group "%rgname%" --nsg-name "%vmname%NSG" --name "Port_8080" --access allow --protocol Tcp --direction Inbound --priority 120 --source-address-prefix "*" --source-port-range "*" --destination-address-prefix "*" --destination-port-range 8080

az network nsg rule list --resource-group "%rgname%" --nsg-name "%vmname%NSG"

rem show VM's public ip address
az vm show -g "%rgname%" -n "%vmname%" -d --query "publicIps" -o tsv

rem login to the VM and do the following to avoid always running docker with sudo
rem
rem chmod +x download-azure-container-script.sh
rem ./download-azure-container-script.sh
rem
rem this will download the azure-container-services-tutorial.sh


echo "password: %vmpwd%"
