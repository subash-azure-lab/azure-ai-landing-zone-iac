locals {
  tags = {
    CostCenter  = var.cost_center
    Environment = var.environment
  }

  # First usable address in AzureFirewallSubnet (10.0.1.0/26); the firewall gets this IP.
  firewall_private_ip = "10.0.1.4"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-lz-${var.environment}-tf"
  location = var.location
  tags     = local.tags
}

module "route_table_spoke1" {
  source              = "./modules/routetable"
  name                = "spoke1-udr"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  firewall_private_ip = local.firewall_private_ip
  tags                = local.tags
}

module "hub" {
  source              = "./modules/vnet"
  name                = "hub-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_prefix      = "10.0.0.0/16"
  tags                = local.tags

  subnets = [
    { name = "AzureFirewallSubnet", prefix = "10.0.1.0/26" },
    { name = "AzureBastionSubnet", prefix = "10.0.2.0/26" },
    { name = "GatewaySubnet", prefix = "10.0.3.0/27" },
  ]
}

module "spoke1" {
  source              = "./modules/vnet"
  name                = "spoke1-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_prefix      = "10.1.0.0/16"
  tags                = local.tags

  subnets = [
    { name = "aks-subnet", prefix = "10.1.1.0/24" },
    { name = "vm-subnet", prefix = "10.1.5.0/24" },
  ]
}

module "spoke2" {
  source              = "./modules/vnet"
  name                = "spoke2-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_prefix      = "10.2.0.0/16"
  tags                = local.tags

  subnets = [
    { name = "data-subnet", prefix = "10.2.1.0/24" },
  ]
}

# Attach the route table to spoke1's aks-subnet.
resource "azurerm_subnet_route_table_association" "spoke1_aks" {
  subnet_id      = module.spoke1.subnet_ids["aks-subnet"]
  route_table_id = module.route_table_spoke1.id
}

# Peerings: each direction is its own resource. Spokes are not peered to each other.
module "peer_hub_to_spoke1" {
  source                    = "./modules/peering"
  name                      = "hub-to-spoke1"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.hub.name
  remote_virtual_network_id = module.spoke1.id
}

module "peer_spoke1_to_hub" {
  source                    = "./modules/peering"
  name                      = "spoke1-to-hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.spoke1.name
  remote_virtual_network_id = module.hub.id
}

module "peer_hub_to_spoke2" {
  source                    = "./modules/peering"
  name                      = "hub-to-spoke2"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.hub.name
  remote_virtual_network_id = module.spoke2.id
}

module "peer_spoke2_to_hub" {
  source                    = "./modules/peering"
  name                      = "spoke2-to-hub"
  resource_group_name       = azurerm_resource_group.this.name
  virtual_network_name      = module.spoke2.name
  remote_virtual_network_id = module.hub.id
}
