@description('Name of the resource.')
param name string

@description('List of scoped resources to associate with the Private Link Scope.')
param scopedResourceIds string[] = []
@description('Specifies the default access mode of queries through associated private endpoints in scope. Defaults to Open.')
param queryAccessMode 'Open' | 'PrivateOnly' = 'Open'
@description('Specifies the default access mode of ingestion through associated private endpoints in scope. Defaults to PrivateOnly.')
param ingestionAccessMode 'Open' | 'PrivateOnly' = 'PrivateOnly'

// Deployments

resource privateLinkScope 'Microsoft.Insights/privateLinkScopes@2023-06-01-preview' = {
  name: name
  location: 'global'
  properties: {
    accessModeSettings: {
      queryAccessMode: queryAccessMode
      ingestionAccessMode: ingestionAccessMode
    }
  }
}

resource scopedResources 'Microsoft.Insights/privateLinkScopes/scopedResources@2023-06-01-preview' = [
  for id in scopedResourceIds: {
    name: uniqueString(id)
    parent: privateLinkScope
    properties: {
      kind: 'Resource'
      linkedResourceId: id
      subscriptionLocation: resourceGroup().location
    }
  }
]

// Outputs

@description('ID for the deployed Private Link Scope resource.')
output id string = privateLinkScope.id
@description('Name for the deployed Private Link Scope resource.')
output name string = privateLinkScope.name
