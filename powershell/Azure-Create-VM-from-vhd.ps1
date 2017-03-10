# =======================================================================
#    Azure-Create-VM-From-Image
#
#  1. You need a Generalized VM disk/vhd
#     https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-windows-capture-image
#
#  2. Create a new VM Object with NIC, IP, etc
#
#  3. Create a NEW VM using the source vhd
#
# =======================================================================


# PowerShell Settings ---------------------------------------------------

# Enable verbose output and stop on error
$VerbosePreference = 'Continue'
$ErrorActionPreference = 'Stop'

# PARAMETERS ------------------------------------------------------------
$Location = "West Europe"
$ResourceGroupName = "PRODWARE365"

# SET AZURE SUBSCRIPTION ------------------------------------------------

# List Azure Subscriptions under this Azure Account
#Get-AzureSubscription | Format-Table SubscriptionName, IsDefault, IsCurrent, CurrentStorageAccountName

# Set Default Subscription for this session
$SubscriptionName = 'Microsoft Azure Sponsorship'
Select-AzureSubscription -SubscriptionName $SubscriptionName

# Get Default Azure Subscription
$AzureSubscription = Get-AzureSubscription -Current

# SET Azure Account -----------------------------------------------------
#Add-AzureRmAccount -SubscriptionName $SubscriptionName

# Add Azure Account to local Powershell session - will prompt for login
#Add-AzureAccount 

# Show Current Azure Account
#$AzureAccount = Get-AzureAccount

# Silent Login, but account must be part of an organizational account
#$userName = "<your organizational account user name>"
#$securePassword = ConvertTo-SecureString -String "<your organizational account password>" -AsPlainText -Force
#$cred = New-Object System.Management.Automation.PSCredential($userName, $securePassword)
#Add-AzureAccount -Credential $cred 

# Storage Account SOURCE ------------------------------------------------

# Get Storage Account Key from Storage Account Name - use Azure storage explorer (http://storageexplorer.com/)
$ConnectionString = "DefaultEndpointsProtocol=https;AccountName=prodware365demo;AccountKey=p+VO8tV510PyFYh/7IarWIYCKeck6NVaF8APU1IPpNytZBrIXV/MoWztDoWW0V68F9sz9ioAL5UXPUgjDMj7EQ==;BlobEndpoint=https://prodware365demo.blob.core.windows.net/;"
$AzureStorageContext = New-AzureStorageContext -ConnectionString $ConnectionString
#Write-Output $AzureStorageContext

# VM SOURCE -------------------------------------------------------------
$SourceVMVHDName = "PRODWARE365DEMO20161204172527.vhd"
$SourceVMStorageContainerURL = $AzureStorageContext.BlobEndPoint + 'vhds/' + $SourceVMVHDName
#Write-Output $SourceVMStorageContainerURL

# VM TARGET -------------------------------------------------------------
$ComputerName = "Prod365demo2" #up to 15 characters long
$VMName = "Prodware365demo2"
$VMSize = "Standard_DS2_V2"
$VM = New-AzureRmVMConfig -VMName $VMName -VMSize $VMSize

# VM Credentials --------------------------------------------------------
$user = "admin"
$password = "password"
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($user, $securePassword) 
$VM = Set-AzureRmVMOperatingSystem -VM $VM -Windows -ComputerName $ComputerName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

# Get Virtual Network ---------------------------------------------------
$VNetName = "Prodware365-vnet"
$AzureVirtualNetwork = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName
#Write-Output $AzureVirtualNetwork
$SubnetName = $AzureVirtualNetwork.Subnets[0].Name
$SubnetId =  $AzureVirtualNetwork.Subnets[0].Id
#Write-Output $SubnetName

# Create Network Interface
$PublicIpAddressName = $VMName + "-ip"
$PublicIpAddress = New-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $PublicIpAddressName -Location $Location -AllocationMethod Dynamic -DomainNameLabel $VMName.ToLower()
$NetworkInterface = New-AzureRmNetworkInterface -Force -Name ('nic' + $VMName) -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $subnetId -PublicIpAddressId $PublicIpAddress.Id

# Add Network Interface to VM
$VM = Add-AzureRmVMNetworkInterface -VM $VM -Id $NetworkInterface.Id

# ADD Azure OS Disk (vhd) -----------------------------------------------
$osDiskName = $VMName+'_osDisk'
$osDiskCaching = 'ReadWrite'
$osDiskVhdUri = $AzureStorageContext.BlobEndPoint + 'vhds/' + $VMName + "_os.vhd"

$VM = Set-AzureRmVMOSDisk -VM $VM -Name $VMName -VhdUri $osDiskVhdUri -CreateOption fromImage -SourceImageUri $SourceVMStorageContainerURL -Windows

# ADD VM TARGET to Azure ------------------------------------------------
Write-Verbose 'Creating VM...'  
$result = New-AzureRmVM -ResourceGroupName $resourceGroupName -Location $Location -VM $VM

if($result.Status -eq 'Succeeded') {  
    $result
    Write-Verbose ('VM named ''{0}'' is now ready, you can connect using username: {1} and password: {2}' -f $vmName, $user, $password)
} else {
    Write-Error 'Virtual machine was not created successfully.'
}
