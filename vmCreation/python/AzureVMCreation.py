import json
import sys
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.network import NetworkManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.network.models import NetworkSecurityGroup, SecurityRule
from azure.mgmt.compute.models import VirtualMachine, HardwareProfile, OSProfile, NetworkProfile, NetworkInterfaceReference, StorageProfile, OSDisk, ImageReference, DiskCreateOptionTypes

# Load configuration
config_path = "vmConfigPY.json"
with open(config_path) as config_file:
    config = json.load(config_file)

# Variables
resource_group_name = config["resourceGroupName"]
location = config["location"]
vm_name = config["vmName"]
vnet_name = config["vnetName"]
subnet_name = config["subnetName"]
nic_name = config["nicName"]
public_ip_name = config["publicIpName"]
nsg_name = config["nsgName"]
password = config["password"]

# Initialize clients
credential = DefaultAzureCredential()
subscription_id = "5847b56f-d404-4e91-9b8b-8920bf35a663"
resource_client = ResourceManagementClient(credential, subscription_id)
network_client = NetworkManagementClient(credential, subscription_id)
compute_client = ComputeManagementClient(credential, subscription_id)

# Create Resource Group
def create_resource_group():
    print("Creating resource group...")
    resource_client.resource_groups.create_or_update(
        resource_group_name, {"location": location}
    )

# Create Virtual Network
def create_virtual_network():
    print("Creating virtual network...")
    vnet = network_client.virtual_networks.begin_create_or_update(
        resource_group_name,
        vnet_name,
        {
            "location": location,
            "address_space": {"address_prefixes": ["10.0.0.0/16"]},
        },
    ).result()
    return vnet

# Create Subnet
def create_subnet(vnet):
    print("Creating subnet...")
    subnet = network_client.subnets.begin_create_or_update(
        resource_group_name,
        vnet_name,
        subnet_name,
        {"address_prefix": "10.0.1.0/24"},
    ).result()
    return subnet

# Create Public IP
def create_public_ip():
    print("Creating public IP...")
    public_ip = network_client.public_ip_addresses.begin_create_or_update(
        resource_group_name,
        public_ip_name,
        {
            "location": location,
            "public_ip_allocation_method": "Static",
        },
    ).result()
    return public_ip

# Create Network Security Group
def create_nsg():
    print("Creating network security group...")
    nsg = network_client.network_security_groups.begin_create_or_update(
        resource_group_name,
        nsg_name,
        {"location": location},
    ).result()

    print("Creating security rules...")
    ssh_rule = SecurityRule(
        protocol="Tcp",
        direction="Inbound",
        source_address_prefix="*",
        source_port_range="*",
        destination_address_prefix="*",
        destination_port_range="22",
        access="Allow",
        priority=100,
        name="AllowSSH",
    )
    network_client.security_rules.begin_create_or_update(
        resource_group_name, nsg_name, "AllowSSH", ssh_rule
    ).result()

    rdp_rule = SecurityRule(
        protocol="Tcp",
        direction="Inbound",
        source_address_prefix="*",
        source_port_range="*",
        destination_address_prefix="*",
        destination_port_range="3389",
        access="Allow",
        priority=200,
        name="AllowRDP",
    )
    network_client.security_rules.begin_create_or_update(
        resource_group_name, nsg_name, "AllowRDP", rdp_rule
    ).result()

    return nsg

# Create Network Interface
def create_nic(subnet, public_ip, nsg):
    print("Creating network interface...")
    nic = network_client.network_interfaces.begin_create_or_update(
        resource_group_name,
        nic_name,
        {
            "location": location,
            "ip_configurations": [
                {
                    "name": "ipconfig1",
                    "subnet": {"id": subnet.id},
                    "public_ip_address": {"id": public_ip.id},
                }
            ],
            "network_security_group": {"id": nsg.id},
        },
    ).result()
    return nic

# Configure and Create VM
def create_vm(nic):
    print("Creating virtual machine...")
    vm = compute_client.virtual_machines.begin_create_or_update(
        resource_group_name,
        vm_name,
        {
            "location": location,
            "hardware_profile": {"vm_size": "Standard_D2s_v3"},
            "storage_profile": {
                "image_reference": {
                    "publisher": "MicrosoftWindowsServer",
                    "offer": "WindowsServer",
                    "sku": "2019-Datacenter",
                    "version": "latest",
                },
                "os_disk": {
                    "create_option": DiskCreateOptionTypes.FROM_IMAGE,
                    "disk_size_gb": 128,
                },
            },
            "os_profile": {
                "computer_name": vm_name,
                "admin_username": "azureuser",
                "admin_password": password,
            },
            "network_profile": {
                "network_interfaces": [{"id": nic.id}],
            },
        },
    ).result()
    return vm

# Main function
def main():
    create_resource_group()
    vnet = create_virtual_network()
    subnet = create_subnet(vnet)
    public_ip = create_public_ip()
    nsg = create_nsg()
    nic = create_nic(subnet, public_ip, nsg)
    create_vm(nic)
    print("VM creation complete.")

if __name__ == "__main__":
    main()
