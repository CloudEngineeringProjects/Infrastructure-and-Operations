# Ubuntu/Debian
$configPath = "$PSScriptRoot\vmConfigPS.json"
$config = Get-Content -Path  $configPath| ConvertFrom-Json

# Variables
$resourceGroupName = $config.resourceGroupName
$location = $config.location
$vmName = $config.vmName
$vnetName = $config.vnetName
$subnetName = $config.subnetName
$nicName = $config.nicName
$publicIpName = $config.publicIpName
$nsgName = $config.nsgName
$password =$config.password


# Create Resource Group
function CreateResourceGroup($resourceGroupName, $location) {
    try {
        New-AzResourceGroup -Name $resourceGroupName -Location $location
    }
    catch {
        Write-Host "Error occurred while trying to create the resource group. Error: $($_.Exception.Message)"
        exit
    }
}

# Create Virtual Network
function CreateVirtualNetwork($resourceGroupName, $location, $vnetName) {
    try {
        $vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location -Name $vnetName -AddressPrefix "10.0.0.0/16"
        return $vnet
    }
    catch {
        Write-Host "Error occurred while trying to create the virtual network. Error: $($_.Exception.Message)"
        exit
    }
}

# Add Subnet Configuration
function CreateSubnet($subnetName, $vnet) {
    try {
        $vnet | Add-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix "10.0.1.0/24" | Set-AzVirtualNetwork
        $updatedVnet = Get-AzVirtualNetwork -ResourceGroupName $vnet.ResourceGroupName -Name $vnet.Name
        $subnet = $updatedVnet.Subnets | Where-Object { $_.Name -eq $subnetName }
        return $subnet
    }
    catch {
        Write-Host "Error occurred while trying to add the subnet. Error: $($_.Exception.Message)"
        exit
    }
}

# Create Public IP Address
function CreatePublicIP($resourceGroupName, $location, $publicIpName) {
    try {
        $publicIp = New-AzPublicIpAddress -ResourceGroupName $resourceGroupName -Location $location -Name $publicIpName -AllocationMethod Static
        return $publicIp
    }
    catch {
        Write-Host "Error occurred while trying to create the public IP. Error: $($_.Exception.Message)"
        exit
    }
}

# Create Network Security Group
function CreateNSG($resourceGroupName, $location, $nsgName) {
    try {
        $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsgName
        return $nsg
    }
    catch {
        Write-Host "Error occurred while trying to create the network security group. Error: $($_.Exception.Message)"
        exit
    }
}

# Create Security Rule
function CreateNSGRule($nsg) {
    try {
        # Allow SSH (port 22)
        $sshRule = New-AzNetworkSecurityRuleConfig -Name "AllowSSH" -Protocol "Tcp" -Direction "Inbound" -Priority 100 -Access "Allow" `
            -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "22"
        $nsg.SecurityRules.Add($sshRule)

        # Allow RDP (port 3389)
        $rdpRule = New-AzNetworkSecurityRuleConfig -Name "AllowRDP" -Protocol "Tcp" -Direction "Inbound" -Priority 200 -Access "Allow" `
            -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "3389"
        $nsg.SecurityRules.Add($rdpRule)

        Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg
    }
    catch {
        Write-Host "Error occurred while trying to create the security rule. Error: $($_.Exception.Message)"
        exit
    }
}

# Create Network Interface Card (NIC)
function CreateNIC($nicName, $location, $nsg, $publicIp, $subnet, $resourceGroupName) {
    $subnet = $subnet[1]
    try {
        $nic = New-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -Location $location `
            -SubnetId $subnet.Id -PublicIpAddressId $publicIp.Id -NetworkSecurityGroupId $nsg.Id
        return $nic
    }
    catch {
        Write-Host "Error occurred while trying to create the network interface card. Error: $($_.Exception.Message)"
        exit
    }
}

# Create Login Credentials
function CreateCredential($vmName) {
    try {
        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential ($vmName, $securePassword)
        return $credential
    }
    catch {
        Write-Host "Error occurred while trying to create the login credentials. Error: $($_.Exception.Message)"
        exit
    }
}

# Configure the Virtual Machine
function VmConfiguration($vmName, $nic, $credential) {
    try {
        # Select a VM size with 8GB RAM (e.g., Standard_D2s_v3)
        $vmConfig = New-AzVMConfig -VMSize "Standard_D2s_v3" -VMName $vmName

        # Set operating system details
        $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $credential

        # Set the OS image
        $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Sku "2019-Datacenter" -Version "latest"

        # Attach the NIC
        $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

        # Configure the OS disk to 128GB
        $vmConfig = Set-AzVMOSDisk -VM $vmConfig -CreateOption FromImage -DiskSizeInGB 128 -Caching ReadWrite

        return $vmConfig
    }
    catch {
        Write-Host "Error occurred while configuring the VM. Error: $($_.Exception.Message)"
        exit
    }
}

# Create the Virtual Machine
function CreateVm($resourceGroupName, $location, $vmConfig) {
    try {
        New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
    }
    catch {
        Write-Host "Error occurred while creating the VM. Error: $($_.Exception.Message)"
        exit
    }
}

# Log in to Azure
function Login {
    try {
        Connect-AzAccount -Subscription "YOUR_SUBSCRIPTION_ID"
    }
    catch {
        Write-Host "Error occurred while logging in to Azure. Error: $($_.Exception.Message)"
        exit
    }
}

# Main Run Function
function Run {
    #Login
    CreateResourceGroup $resourceGroupName $location
    $vnet = CreateVirtualNetwork $resourceGroupName $location $vnetName
    $subnet = CreateSubnet $subnetName $vnet
    $publicIp = CreatePublicIP $resourceGroupName $location $publicIpName
    $nsg = CreateNSG $resourceGroupName $location $nsgName
    CreateNSGRule $nsg
    $nic = CreateNIC $nicName $location $nsg $publicIp $subnet $resourceGroupName
    $credential = CreateCredential $vmName
    $vmConfig = VmConfiguration $vmName $nic $credential
    CreateVm $resourceGroupName $location $vmConfig
}

# Execute the script
Run

