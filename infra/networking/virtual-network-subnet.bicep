@description('Name of the resource.')
param name string

@description('Name of the existing virtual network to deploy the subnet to.')
param virtualNetworkName string
@description('The address block reserved for this virtual network subnet in CIDR notation.')
param addressPrefix string
@description('Whether to enable apply network policies on private endpoint in the subnet. Defaults to Enabled.')
param privateEndpointNetworkPolicies 'Enabled' | 'Disabled' = 'Enabled'
@description('Whether to enable apply network policies on private link service in the subnet. Defaults to Enabled.')
param privateLinkServiceNetworkPolicies 'Enabled' | 'Disabled' = 'Enabled'
@description('List of service delegations in this virtual network subnet.')
param delegations object[]?
@description('Subnet configuration for the existing network security group to attach.')
param networkSecurityGroup object?

// Deployments

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetworkName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: name
  parent: virtualNetwork
  properties: {
    addressPrefix: addressPrefix
    privateEndpointNetworkPolicies: privateEndpointNetworkPolicies
    privateLinkServiceNetworkPolicies: privateLinkServiceNetworkPolicies
    delegations: delegations
    networkSecurityGroup: networkSecurityGroup
  }
}

// Outputs

@description('ID for the deployed Virtual Network subnet resource.')
output id string = subnet.id
@description('Name for the deployed Virtual Network subnet resource.')
output name string = subnet.name

// Definitions

@export()
@description('Information about a subnet to be created in the virtual network.')
type subnetInfo = {
  @description('Name of the subnet.')
  name: string
  @description('Address prefix for the subnet.')
  addressPrefix: string
  @description('Whether to enable apply network policies on private endpoint in the subnet.')
  privateEndpointNetworkPolicies: 'Enabled' | 'Disabled'
  @description('Whether to enable apply network policies on private link service in the subnet.')
  privateLinkServiceNetworkPolicies: 'Enabled' | 'Disabled'
  @description('List of service delegations in this virtual network subnet.')
  delegations: object[]?
  @description('Subnet configuration for the existing network security group to attach.')
  networkSecurityGroup: object?
}
