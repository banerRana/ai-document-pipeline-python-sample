import { subnetInfo } from './virtual-network-subnet.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('Whether to deploy the virtual network and subnet resources.')
param deploy bool = true
@description('List of address blocks reserved for this virtual network in CIDR notation.')
param addressPrefixes string[] = ['10.0.0.0/16']
@description('List of subnets to be created in the virtual network.')
param subnets subnetInfo[] = []

// Deployments

resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = if (!deploy) {
  name: name
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = if (deploy) {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
  }
}

@batchSize(1)
module virtualNetworkSubnets './virtual-network-subnet.bicep' = [
  for subnet in subnets: if (deploy) {
    name: subnet.name
    params: {
      name: subnet.name
      virtualNetworkName: virtualNetwork.name
      addressPrefix: subnet.addressPrefix
      privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
      privateLinkServiceNetworkPolicies: subnet.privateLinkServiceNetworkPolicies
      delegations: subnet.?delegations ?? null
      networkSecurityGroup: subnet.?networkSecurityGroup ?? null
    }
  }
]

// Outputs

@description('ID for the deployed Virtual Network resource.')
output id string = deploy ? virtualNetwork.id : existingVirtualNetwork.id
@description('Name for the deployed Virtual Network resource.')
output name string = deploy ? virtualNetwork.name : existingVirtualNetwork.name
@description('List of details for the subnets deployed in the Virtual Network.')
output subnets array = [
  for (subnet, i) in subnets: {
    id: resourceId(
      resourceGroup().name,
      'Microsoft.Network/virtualNetworks/subnets',
      deploy ? virtualNetwork.name : existingVirtualNetwork.name,
      subnet.name
    )
    name: subnet.name
    addressPrefix: subnet.addressPrefix
  }
]
