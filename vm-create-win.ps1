# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-powershell
# https://docs.microsoft.com/en-us/azure/azure-stack/user/azure-stack-quick-create-vm-linux-powershell

$location="West Europe"
# transform userid to lowercase since some Azure resource names don't like uppercase
$userid=$env:USERNAME.tolower()
# generate the VM name from the userid + random digits and then derive every name from that VM name 
$vmname="$userid$(Get-Random)"
$rgname="$($vmname)-rg"
$vmpwd="Pwdpwd$(Get-Random)$(Get-Random)"
$vnetname="$($vmname)-vnet"
$nsgname="$($vmname)-nsg"
$pipname="$($vmname)-pip"
$nicname="$($vmname)-nic"
$StorageAccountName = "$($vmname)stg"
# the AddressPrefix can be any valid class A/B/C (10.*/172.*/192.*) ip addr if not connected to on-prem network via VPN
# if there is a VPN connection to on-prem, you should get these values from your on-prem network admin
$vnetAddressPrefix="192.168.1.0/28"
$subnetAddressPrefix="192.168.1.0/24"

# create secure pwd string and Credentials object
$vmpwdsec = ConvertTo-SecureString $vmpwd -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ( $userid, $vmpwdsec )

# create resource group
New-AzureRmResourceGroup -Name "$rgname" -Location "$location"

# Create a new storage account - use Standard_LRS to save a few $$
$StorageAccount = New-AzureRMStorageAccount -Location "$location" -ResourceGroupName "$rgname" -Type "Standard_LRS" -Name "$StorageAccountName"
# Create a storage container to store the virtual machine image
$container = New-AzureStorageContainer -Name "vhds" -Permission "Blob" -Context  $StorageAccount.Context

# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name "mySubnet" -AddressPrefix $vnetAddressPrefix
# Create a virtual network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName "$rgname" -Location "$location" -Name "$vnetname" -AddressPrefix $subnetAddressPrefix -Subnet $subnetConfig

# Create a public IP address and specify a DNS name
$pip = New-AzureRmPublicIpAddress -ResourceGroupName "$rgname" -Location "$location" -Name "$pipname" -AllocationMethod "Dynamic"

# get our current public ip addr so we can set the NSG below to only allow access from that ip addr
$resp = Invoke-RestMethod "http://ipinfo.io"
$PIPADDR=$resp.ip

# Create an inbound network security group rule for port 22
$nsg22 = New-AzureRmNetworkSecurityRuleConfig -Name "Port_SSH" -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix "$PIPADDR" -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow
$nsg80 = New-AzureRmNetworkSecurityRuleConfig -Name "Port_80" -Protocol Tcp -Direction Inbound -Priority 120 -SourceAddressPrefix "$PIPADDR" -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80 -Access Allow
$nsg8080 = New-AzureRmNetworkSecurityRuleConfig -Name "Port_8080" -Protocol Tcp -Direction Inbound -Priority 140 -SourceAddressPrefix "$PIPADDR" -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 8080 -Access Allow
# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName "$rgname" -Location "$location" -Name "$nsgname" -SecurityRules $nsg22,$nsg80,$nsg88,$nsg8080

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzureRmNetworkInterface -Name "$nicname" -ResourceGroupName "$rgname" -Location "$location" -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# set some various VM config
$vmConfig = New-AzureRmVMConfig -VMName $vmname -VMSize "Standard_D1_v2" | `
    Set-AzureRmVMOperatingSystem -Linux -ComputerName "$vmname" -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName "Canonical" -Offer "UbuntuServer" -Skus "16.04-LTS" -Version "latest" | `
    Add-AzureRmVMNetworkInterface -Id $nic.Id | `
    Set-AzureRmVMBootDiagnostics -Disable

# setup storage
$osDiskUri = '{0}vhds/{1}-osdisk.vhd' -f $StorageAccount.PrimaryEndpoints.Blob.ToString(), $vmname.ToLower()
$vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name "$($vmname)-osdisk" -VhdUri $OsDiskUri -CreateOption FromImage 

# Create a virtual machine
New-AzureRmVM -ResourceGroupName "$rgname" -Location "$location" -VM $vmConfig

# run the installation script
$settings = @{"fileUris" = @("https://raw.githubusercontent.com/cljung/aztechdays/master/ubuntu-install-devtools.sh"); "commandToExecute"= "bash ./ubuntu-install-devtools.sh '$env:USERNAME'" };
Set-AzureRmVMExtension -ResourceGroupName $rgname -VMName $vmname -Name "CustomScriptforLInux" -Publisher "Microsoft.Azure.Extensions" `
                        -TypeHandlerVersion 2.0 -ExtensionType "CustomScript" -Location $location -Settings $settings -WarningAction SilentlyContinue

write-output "Password: $vmpwd"
                        
# remote into the VM and do
# wget https://raw.githubusercontent.com/cljung/aztechdays/master/azure-container-services-tutorial.sh
# chmod +x azure-container-services-tutorial.sh
# dos2unix azure-container-services-tutorial.sh

# Remove-AzureRmResourceGroup -Name $rgname -Force





