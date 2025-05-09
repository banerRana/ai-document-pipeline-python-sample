@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('ID of the subnet from which the private IP will be allocated.')
param subnetId string
@description('ID of the service to which the private endpoint will connect.')
param serviceId string
@description('ID(s) of the group(s) obtained from the remote resource that this private endpoint should connect to.')
param groupIds array = []
@description('List of private DNS zone groups to which the private endpoint will be linked.')
param dnsZoneGroups privateDnsZoneGroupInfo[]

// Deployments

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'privateLinkServiceConnection'
        properties: {
          privateLinkServiceId: serviceId
          groupIds: groupIds
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: '${name}-group'
  properties: {
    privateDnsZoneConfigs: dnsZoneGroups
  }
}

// Outputs

@description('ID for the deployed private endpoint resource.')
output id string = privateEndpoint.id
@description('Name for the deployed private endpoint resource.')
output name string = privateEndpoint.name
@description('Group ID for the deployed private endpoint resource.')
output groupId string? = privateEndpoint.properties.?privateLinkServiceConnections[?0].properties.?groupIds[?0]

// Definitions

@export()
@description('Information about a private DNS zone group.')
type privateDnsZoneGroupInfo = {
  name: string
  properties: {
    privateDnsZoneId: string
  }
}
