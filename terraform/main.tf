locals {
  tags = {
    CostCenter  = var.cost_center
    Environment = var.environment
  }

  # First usable address in AzureFirewallSubnet (10.0.1.0/26); the firewall gets this IP.
  firewall_private_ip = "10.0.1.4"

  # Rules Azure requires on the AzureBastionSubnet NSG.
  bastion_rules = [
    {
      name                       = "AllowHttpsInbound"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_ranges    = ["443"]
      source_address_prefix      = "Internet"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowGatewayManagerInbound"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_ranges    = ["443"]
      source_address_prefix      = "GatewayManager"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowAzureLoadBalancerInbound"
      priority                   = 140
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_ranges    = ["443"]
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    },
    {
      name                       = "AllowBastionHostCommunicationInbound"
      priority                   = 150
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowSshRdpOutbound"
      priority                   = 100
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      destination_port_ranges    = ["22", "3389"]
      source_address_prefix      = "*"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowAzureCloudOutbound"
      priority                   = 110
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      destination_port_ranges    = ["443"]
      source_address_prefix      = "*"
      destination_address_prefix = "AzureCloud"
    },
    {
      name                       = "AllowBastionCommunicationOutbound"
      priority                   = 120
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      destination_port_ranges    = ["8080", "5701"]
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    },
    {
      name                       = "AllowHttpOutbound"
      priority                   = 130
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      destination_port_ranges    = ["80"]
      source_address_prefix      = "*"
      destination_address_prefix = "Internet"
    },
  ]
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

module "nsg_bastion" {
  source              = "./modules/nsg"
  name                = "nsg-bastion-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  rules               = local.bastion_rules
  tags                = local.tags
}

module "nsg_aks" {
  source              = "./modules/nsg"
  name                = "nsg-aks-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

module "nsg_vm" {
  source              = "./modules/nsg"
  name                = "nsg-vm-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

module "nsg_data" {
  source              = "./modules/nsg"
  name                = "nsg-data-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

module "hub" {
  source              = "./modules/vnet"
  name                = "hub-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_prefix      = "10.0.0.0/16"
  tags                = local.tags

  nsg_ids = {
    "AzureBastionSubnet" = module.nsg_bastion.id
  }

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

  nsg_ids = {
    "aks-subnet" = module.nsg_aks.id
    "vm-subnet"  = module.nsg_vm.id
  }

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

  nsg_ids = {
    "data-subnet" = module.nsg_data.id
  }

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
