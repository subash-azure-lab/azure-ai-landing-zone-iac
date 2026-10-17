output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "hub_vnet_id" {
  value = module.hub.id
}

output "spoke1_vnet_id" {
  value = module.spoke1.id
}

output "spoke2_vnet_id" {
  value = module.spoke2.id
}
