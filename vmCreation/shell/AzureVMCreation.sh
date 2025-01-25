#!/bin/bash

# Set the path to the JSON configuration file
configPath="./vmConfigSH.json"

# Read configuration values from the JSON file
resourceGroupName=$(jq -r '.resourceGroupName' "$configPath")
location=$(jq -r '.location' "$configPath")
vmName=$(jq -r '.vmName' "$configPath")
vnetName=$(jq -r '.vnetName' "$configPath")
subnetName=$(jq -r '.subnetName' "$configPath")
nicName=$(jq -r '.nicName' "$configPath")
publicIpName=$(jq -r '.publicIpName' "$configPath")
nsgName=$(jq -r '.nsgName' "$configPath")
password=$(jq -r '.password' "$configPath")

# Login to Azure
function login_to_azure() {
    #az login --use-device-code
}

# Create a resource group
function create_resource_group() {
    echo "Creating resource group: $resourceGroupName in $location"
    az group create --name "$resourceGroupName" --location "$location"
}

# Create a virtual network
function create_virtual_network() {
    echo "Creating virtual network: $vnetName"
    az network vnet create \
        --resource-group "$resourceGroupName" \
        --name "$vnetName" \
        --address-prefix "10.0.0.0/16" \
        --subnet-name "$subnetName" \
        --subnet-prefix "10.0.1.0/24"
}

# Create a public IP address
function create_public_ip() {
    echo "Creating public IP: $publicIpName"
    az network public-ip create \
        --resource-group "$resourceGroupName" \
        --name "$publicIpName" \
        --allocation-method Static
}

# Create a network security group
function create_nsg() {
    echo "Creating network security group: $nsgName"
    az network nsg create \
        --resource-group "$resourceGroupName" \
        --name "$nsgName"
}

# Create security rules
function create_security_rules() {
    echo "Adding security rules to NSG: $nsgName"
    az network nsg rule create \
        --resource-group "$resourceGroupName" \
        --nsg-name "$nsgName" \
        --name "AllowSSH" \
        --priority 100 \
        --protocol Tcp \
        --access Allow \
        --direction Inbound \
        --source-address-prefix "*" \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 22

    az network nsg rule create \
        --resource-group "$resourceGroupName" \
        --nsg-name "$nsgName" \
        --name "AllowRDP" \
        --priority 200 \
        --protocol Tcp \
        --access Allow \
        --direction Inbound \
        --source-address-prefix "*" \
        --source-port-range "*" \
        --destination-address-prefix "*" \
        --destination-port-range 3389
}

# Create a network interface
function create_nic() {
    echo "Creating network interface: $nicName"
    az network nic create \
        --resource-group "$resourceGroupName" \
        --name "$nicName" \
        --vnet-name "$vnetName" \
        --subnet "$subnetName" \
        --network-security-group "$nsgName" \
        --public-ip-address "$publicIpName"
}

# Create a virtual machine
function create_vm() {
    echo "Creating virtual machine: $vmName"
    az vm create \
        --resource-group "$resourceGroupName" \
        --name "$vmName" \
        --image "Win2019Datacenter" \
        --admin-username "azureuser" \
        --admin-password "$password" \
        --size "Standard_D2s_v3" \
        --nics "$nicName" \
        --os-disk-size-gb 128
}

# Main execution
function main() {
    login_to_azure
    create_resource_group
    create_virtual_network
    create_public_ip
    create_nsg
    create_security_rules
    create_nic
    create_vm
    echo "Virtual machine creation complete!"
}

# Execute the script
main
