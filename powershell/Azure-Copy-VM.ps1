# =============== FIRST TIME ==================

# Install the Azure Resource Manager modules from the PowerShell Gallery
# Install-Module AzureRM


# =============== PARAMETERS ==================

$SubscriptionName = "Microsoft Azure Sponsorship"

## VM Account
# Credentials for Local Admin account you created in the sysprepped (generalized) vhd image
$VMLocalAdminUser = Read-Host -Prompt 'vm admin username:'
$VMLocalAdminPass = Read-Host -Prompt 'vm admin password:'
$VMLocalAdminSecurePassword = ConvertTo-SecureString $VMLocalAdminPass -AsPlainText -Force 
## Azure Account
$LocationName = "westeurope"
$ResourceGroupName = "PRODWARE365"
# This a Premium_LRS storage account. 
# It is required in order to run a client VM with efficiency and high performance.
$StorageAccount = "prodware365demo"

## Source VM
$OSDiskName = "PRODWARE365DEMO"
$ComputerName = "PRODWARE365DEMO"
$SourceImageUri = "https://prodware365demo.blob.core.windows.net/vhds/PRODWARE365DEMO20161204172527.vhd" # "https://Mydisk.blob.core.windows.net/vhds/MyOSImage.vhd"

## Target VM
$OSDiskUri = "https://prodware365demo.blob.core.windows.net/vhds/PRODWARE365DEMO2.vhd"
$VMName = "PRODWARE365DEMO2"
# Modern hardware environment with fast disk, high IOPs performance. 
# Required to run a client VM with efficiency and performance
$VMSize = "Standard_DS2_V2" 
$OSDiskCaching = "ReadWrite"
$OSCreateOption = "FromImage"

## Networking
# $DNSNameLabel = "PRODWARE365DEMO2" # mydnsname.westus.cloudapp.azure.com
$NetworkName = "PRODWARE365DEMO2-vnet"
$NICName = "prodware365demo2"
$PublicIPAddressName = "PRODWARE365DEMO2"
$SubnetName = "PRODWARE365DEMO2"
$SubnetAddressPrefix = "10.2.0.0/24"
$VnetAddressPrefix = "10.2.0.0/16"


# Login to Azure Account
# You can also use a specific Tenant if you would like a faster log in experience
# Login-AzureRmAccount -TenantId xxxx
Login-AzureRmAccount

# To select a default subscription for your current session.
# This is useful when you have multiple subscriptions.
Get-AzureRmSubscription -SubscriptionName $SubscriptionName | Select-AzureRmSubscription

# To select the default storage context for your current session
Set-AzureRmCurrentStorageAccount -ResourceGroupName $ResourceGroupName -StorageAccountName $StorageAccount

# ============ DIAGNOSTIC ==============

# View your current Azure PowerShell session context
# This session state is only applicable to the current session and will not affect other sessions
#Get-AzureRmContext

# ============ COPY VM ==================

$SingleSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
$Vnet = New-AzureRmVirtualNetwork -Name $NetworkName -ResourceGroupName $ResourceGroupName -Location $LocationName -AddressPrefix $VnetAddressPrefix -Subnet $SingleSubnet
$PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -ResourceGroupName $ResourceGroupName -Location $LocationName -AllocationMethod Dynamic
# If you have cloud service use this line including -DomainNameLabel
#$PIP = New-AzureRmPublicIpAddress -Name $PublicIPAddressName -DomainNameLabel $DNSNameLabel -ResourceGroupName $ResourceGroupName -Location $LocationName -AllocationMethod Dynamic
$NIC = New-AzureRmNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroupName -Location $LocationName -SubnetId $Vnet.Subnets[0].Id -PublicIpAddressId $PIP.Id

$Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $VMLocalAdminUser, $VMLocalAdminSecurePassword

$VirtualMachine = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzureRmVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $Credential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzureRmVMNetworkInterface -VM $VirtualMachine -Id $NIC.Id
$VirtualMachine = Set-AzureRmVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -SourceImageUri $SourceImageUri -Caching $OSDiskCaching -CreateOption $OSCreateOption -Windows

New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $LocationName -VM $VirtualMachine -Verbose