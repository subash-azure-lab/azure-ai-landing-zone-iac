// Generic virtual network module: one address space, a list of subnets.
// Each subnet is { name, prefix, routeTableId } where routeTableId may be '' (no route table).

@description('Name of the virtual network')
param name string

@description('Azure region')
param location string = resourceGroup().location

@description('Address space of the VNet, e.g. 10.1.0.0/16')
param addressPrefix string

@description('Subnets to create. Each item: { name: string, prefix: string, routeTableId: string }')
param subnets array

@description('Tags applied to the VNet')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for s in subnets: {
      name: s.name
      properties: {
        addressPrefix: s.prefix
        routeTable: empty(s.routeTableId) ? null : {
          id: s.routeTableId
        }
      }
    }]
  }
}

output id string = vnet.id
output name string = vnet.name
