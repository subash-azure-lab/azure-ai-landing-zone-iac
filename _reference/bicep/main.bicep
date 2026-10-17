// Hub-spoke network, deployed at resource group scope.
//   hub-vnet    10.0.0.0/16  (firewall, bastion, gateway subnets)
//   spoke1-vnet 10.1.0.0/16  (aks-subnet with route table, vm-subnet)
//   spoke2-vnet 10.2.0.0/16  (data-subnet)
// Peerings hub <-> spoke1 and hub <-> spoke2. Spokes are NOT peered to each other.

targetScope = 'resourceGroup'

@description('Azure region')
param location string = resourceGroup().location

@description('Environment name, used in tags')
param environment string = 'dev'

@description('Cost center tag required by policy')
param costCenter string = 'AI-Platform'

@description('Private IP the Azure Firewall will get in AzureFirewallSubnet (first usable address)')
param firewallPrivateIp string = '10.0.1.4'

var tags = {
  CostCenter: costCenter
  Environment: environment
}

module routeTable 'modules/routetable.bicep' = {
  name: 'routeTable'
  params: {
    name: 'spoke1-udr'
    location: location
    firewallPrivateIp: firewallPrivateIp
    tags: tags
  }
}

module hub 'modules/vnet.bicep' = {
  name: 'hub'
  params: {
    name: 'hub-vnet'
    location: location
    addressPrefix: '10.0.0.0/16'
    tags: tags
    subnets: [
      { name: 'AzureFirewallSubnet', prefix: '10.0.1.0/26', routeTableId: '' }
      { name: 'AzureBastionSubnet', prefix: '10.0.2.0/26', routeTableId: '' }
      { name: 'GatewaySubnet', prefix: '10.0.3.0/27', routeTableId: '' }
    ]
  }
}

module spoke1 'modules/vnet.bicep' = {
  name: 'spoke1'
  params: {
    name: 'spoke1-vnet'
    location: location
    addressPrefix: '10.1.0.0/16'
    tags: tags
    subnets: [
      { name: 'aks-subnet', prefix: '10.1.1.0/24', routeTableId: routeTable.outputs.id }
      { name: 'vm-subnet', prefix: '10.1.5.0/24', routeTableId: '' }
    ]
  }
}

module spoke2 'modules/vnet.bicep' = {
  name: 'spoke2'
  params: {
    name: 'spoke2-vnet'
    location: location
    addressPrefix: '10.2.0.0/16'
    tags: tags
    subnets: [
      { name: 'data-subnet', prefix: '10.2.1.0/24', routeTableId: '' }
    ]
  }
}

module hubToSpoke1 'modules/peering.bicep' = {
  name: 'hubToSpoke1'
  params: {
    localVnetName: hub.outputs.name
    peeringName: 'hub-to-spoke1'
    remoteVnetId: spoke1.outputs.id
  }
}

module spoke1ToHub 'modules/peering.bicep' = {
  name: 'spoke1ToHub'
  params: {
    localVnetName: spoke1.outputs.name
    peeringName: 'spoke1-to-hub'
    remoteVnetId: hub.outputs.id
  }
}

module hubToSpoke2 'modules/peering.bicep' = {
  name: 'hubToSpoke2'
  params: {
    localVnetName: hub.outputs.name
    peeringName: 'hub-to-spoke2'
    remoteVnetId: spoke2.outputs.id
  }
}

module spoke2ToHub 'modules/peering.bicep' = {
  name: 'spoke2ToHub'
  params: {
    localVnetName: spoke2.outputs.name
    peeringName: 'spoke2-to-hub'
    remoteVnetId: hub.outputs.id
  }
}

output hubVnetId string = hub.outputs.id
output spoke1VnetId string = spoke1.outputs.id
output spoke2VnetId string = spoke2.outputs.id
