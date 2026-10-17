// One direction of a VNet peering. Deploy it twice (once from each side) for a working peering.

@description('Name of the existing local VNet')
param localVnetName string

@description('Name of this peering resource, e.g. hub-to-spoke1')
param peeringName string

@description('Resource ID of the remote VNet')
param remoteVnetId string

@description('Allow traffic forwarded by an appliance (needed for hub firewall designs)')
param allowForwardedTraffic bool = true

resource localVnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: localVnetName
}

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: localVnet
  name: peeringName
  properties: {
    remoteVirtualNetwork: {
      id: remoteVnetId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}
