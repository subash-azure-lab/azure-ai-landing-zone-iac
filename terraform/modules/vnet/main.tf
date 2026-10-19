resource "azurerm_virtual_network" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.address_prefix]
  tags                = var.tags
}

# One subnet resource per item in the list. The map key is the subnet name,
# so adding or removing a subnet does not shift the others.
resource "azurerm_subnet" "this" {
  for_each             = { for s in var.subnets : s.name => s }
  name                 = each.value.name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.prefix]
}

# Attach an NSG to each subnet named in var.nsg_ids.
# The keys (subnet names) are known at plan time; only the NSG IDs are unknown until apply.
resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.nsg_ids
  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = each.value
}
