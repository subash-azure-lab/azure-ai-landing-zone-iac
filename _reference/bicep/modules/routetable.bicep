// Route table that forces all outbound traffic (0.0.0.0/0) to a firewall / virtual appliance.

@description('Name of the route table')
param name string

@description('Azure region')
param location string = resourceGroup().location

@description('Private IP of the firewall (next hop)')
param firewallPrivateIp string

@description('Tags applied to the route table')
param tags object = {}

resource routeTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        name: 'force-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

output id string = routeTable.id
