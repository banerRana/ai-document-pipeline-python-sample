import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('ID for the Managed Identity associated with the App Configuration Store instance. Defaults to the system-assigned identity.')
param identityId string?
@description('Application settings to add to App Configuration')
param appSettings appSettingInfo[] = []
@description('Secure application settings to add to App Configuration')
param secureAppSettings appSettingInfo[] = []
@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
@description('Whether to disable local (key-based) authentication. Defaults to false.')
param disableLocalAuth bool = false
@description('Whether purge protection is enabled. Defaults to true.')
param enablePurgeProtection bool = true
@description('Number of days to retain soft-deleted configuration. Defaults to 7.')
param retentionInDays int = 7
@description('Role assignments to create for the App Configuration Store.')
param roleAssignments roleAssignmentInfo[] = []

// Deployments

resource appConfigStore 'Microsoft.AppConfiguration/configurationStores@2024-05-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'standard'
  }
  identity: {
    type: identityId == null ? 'SystemAssigned' : 'UserAssigned'
    userAssignedIdentities: identityId == null
      ? null
      : {
          '${identityId}': {}
        }
  }
  properties: {
    disableLocalAuth: disableLocalAuth
    enablePurgeProtection: enablePurgeProtection
    encryption: {}
    publicNetworkAccess: publicNetworkAccess
    softDeleteRetentionInDays: retentionInDays
  }
}

resource keyValue 'Microsoft.AppConfiguration/configurationStores/keyValues@2024-05-01' = [
  for appSetting in appSettings: {
    parent: appConfigStore
    name: appSetting.name
    properties: {
      contentType: ''
      tags: {}
      value: appSetting.value
    }
  }
]

resource secureKeyValue 'Microsoft.AppConfiguration/configurationStores/keyValues@2024-05-01' = [
  for appSetting in secureAppSettings: {
    parent: appConfigStore
    name: appSetting.name
    properties: {
      contentType: 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'
      tags: {}
      value: appSetting.value
    }
  }
]

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: {
    name: guid(appConfigStore.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: appConfigStore
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.principalType
    }
  }
]

// Outputs

@description('ID for the deployed App Configuration resource.')
output id string = appConfigStore.id
@description('Name for the deployed App Configuration resource.')
output name string = appConfigStore.name
@description('Endpoint for the deployed App Configuration resource.')
output endpoint string = appConfigStore.properties.endpoint
@description('Principal ID for the deployed App Configuration resource.')
output identityPrincipalId string = identityId == null ? appConfigStore.identity.principalId : identityId!

// Definitions

@export()
@description('Information about app settings for the App Configuration Store.')
type appSettingInfo = {
  @description('Name of the key-value pair.')
  name: string
  @description('Value of the key-value pair.')
  value: string
}
