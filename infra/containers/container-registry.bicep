import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('ID for the Managed Identity associated with the Container Registry instance. Defaults to the system-assigned identity.')
param identityId string?
@description('Whether to enable an admin user that has push and pull access. Defaults to false.')
param adminUserEnabled bool = false
@description('Whether to allow public network access. Defaults to Disabled.')
@allowed([
  'Disabled'
  'Enabled'
])
param publicNetworkAccess string = 'Disabled'
@description('Specifies whether zone redundancy is enabled. Defaults to Disabled.')
@allowed([
  'Disabled'
  'Enabled'
])
param zoneRedundancy string = 'Disabled'
@description('Container Registry SKU. Defaults to Standard.')
param sku skuInfo = {
  name: 'Standard'
}
@description('Role assignments to create for the Container Registry.')
param roleAssignments roleAssignmentInfo[] = []

// Deployments

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: identityId == null ? 'SystemAssigned' : 'UserAssigned'
    userAssignedIdentities: identityId == null
      ? null
      : {
          '${identityId}': {}
        }
  }
  sku: sku
  properties: {
    adminUserEnabled: adminUserEnabled
    zoneRedundancy: zoneRedundancy
    publicNetworkAccess: publicNetworkAccess
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSet: {
      defaultAction: 'Deny'
      ipRules: []
    }
  }
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: {
    name: guid(containerRegistry.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: containerRegistry
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.principalType
    }
  }
]

// Outputs

@description('ID for the deployed Container Registry resource.')
output id string = containerRegistry.id
@description('Name for the deployed Container Registry resource.')
output name string = containerRegistry.name
@description('Login server for the deployed Container Registry resource.')
output loginServer string = containerRegistry.properties.loginServer
@description('Principal ID for the deployed AI Services resource.')
output identityPrincipalId string = identityId == null ? containerRegistry.identity.principalId : identityId!

// Definitions

@export()
@description('SKU information for Container Registry.')
type skuInfo = {
  @description('Name of the SKU.')
  name: 'Basic' | 'Premium' | 'Standard'
}
