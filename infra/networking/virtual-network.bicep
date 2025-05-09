import { subnetInfo } from './virtual-network-subnet.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('List of address blocks reserved for this virtual network in CIDR notation.')
param addressPrefixes string[] = ['10.0.0.0/16']
@description('List of subnets to be created in the virtual network.')
param subnets subnetInfo[] = []

// Deployments

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
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
  for subnet in subnets: {
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
output id string = virtualNetwork.id
@description('Name for the deployed Virtual Network resource.')
output name string = virtualNetwork.name
@description('List of details for the subnets deployed in the Virtual Network.')
output subnets array = [
  for (subnet, i) in subnets: {
    id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, subnet.name)
    name: subnet.name
    addressPrefix: subnet.addressPrefix
  }
]
