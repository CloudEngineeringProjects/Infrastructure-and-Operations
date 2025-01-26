output "resource_group_name" {
  value = azurerm_resource_group.resourceGroup.name
}

output "vm_ip_address" {
  value = azurerm_public_ip.publicIP.ip_address
}
