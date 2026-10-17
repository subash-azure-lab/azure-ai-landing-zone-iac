output "id" {
  description = "Resource ID of the VNet"
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Name of the VNet"
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name to subnet resource ID"
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}
