#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
variable "resource_group_name" {
  default = "tf_rg_biokuResources"
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  default = "uk west"
  description = "Azure region for resources"
  type        = string
}

variable "vm_name" {
  default = "biokuVM"
  description = "Name of the virtual machine"
  type        = string
}

variable "vnet_name" {
  default = "biokuVnet"
  description = "Name of the virtual network"
  type        = string
}

variable "subnet_name" {
  default = "biokuSubnet"
  description = "Name of the subnet"
  type        = string
}

variable "nic_name" {
  default = "biokuNIC"
  description = "Name of the network interface"
  type        = string
}

variable "public_ip_name" {
  default = "biokuPublicIP"
  description = "Name of the public IP address"
  type        = string
}

variable "nsg_name" {
  default = "biokuNSG"
  description = "Name of the network security group"
  type        = string
}

variable "admin_password" {
  default = "Pa33w0rd"
  description = "Admin password for the virtual machine"
  type        = string
}

variable "admin_name" {
  default = "Admin_Bioku"
  description = "Admin Username for the virtual machine"
  type        = string
}

variable "vm_size" {
  default = "Standard_D2s_v3"
  description = "Admin Username for the virtual machine"
  type        = string
}
