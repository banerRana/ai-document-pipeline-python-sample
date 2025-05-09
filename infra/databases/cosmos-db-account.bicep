import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('Georeplication locations for the Cosmos DB account. Defaults to the location of the resource group.')
param georeplicationLocations cosmosDbLocation[] = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]
@description('Default consistency policy for the Cosmos DB account. Defaults to Session.')
param defaultConsistencyLevel 'ConsistentPrefix' | 'Eventual' | 'Session' | 'BoundedStaleness' | 'Strong' = 'Session'
@description('Indicates whether automatic failover is enabled for the Cosmos DB account. Defaults to true.')
param enableAutomaticFailover bool = true
@description('Whether to enable public network access. Defaults to Enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'
@description('Role assignments to create for the Cosmos DB account.')
param roleAssignments roleAssignmentInfo[] = []
@description('Data plane role assignments to create for the Cosmos DB account.')
param dataRoleAssignments roleAssignmentInfo[] = []
@description('Max number of stale requests tolerated, if defaultConsistencyLevel is BoundedStaleness. Valid ranges: Single Region: 10 to 2147483647; Multi Region: 100000 to 2147483647.')
@minValue(10)
@maxValue(2147483647)
param maxStalenessPrefix int = 100000
@description('Max time amount of staleness (in seconds) tolerated, if defaultConsistencyLevel is BoundedStaleness. Valid ranges: Single Region: 5 to 84600; Multi Region: 300 to 86400.')
@minValue(5)
@maxValue(86400)
param maxIntervalInSeconds int = 300

// Variables

@description('Cosmos DB consistency policy determined by the defaultConsistencyLevel parameter.')
var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}

// Deployments

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' = {
  name: name
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: consistencyPolicy[defaultConsistencyLevel]
    locations: georeplicationLocations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: enableAutomaticFailover
    publicNetworkAccess: publicNetworkAccess
    enableAnalyticalStorage: true
  }

  resource dataAssignment 'sqlRoleAssignments' = [
    for roleAssignment in dataRoleAssignments: {
      name: guid(cosmosDb.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
      properties: {
        principalId: roleAssignment.principalId
        roleDefinitionId: resourceId(
          'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions',
          cosmosDb.name,
          roleAssignment.roleDefinitionId
        )
        scope: cosmosDb.id
      }
    }
  ]
}

resource assignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in roleAssignments: {
    name: guid(cosmosDb.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: cosmosDb
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.principalType
    }
  }
]

// Outputs

@description('ID for the deployed Cosmos DB resource.')
output id string = cosmosDb.id
@description('Name for the deployed Cosmos DB resource.')
output name string = cosmosDb.name

// Definitions

@export()
@description('Georeplication location for the Cosmos DB account.')
type cosmosDbLocation = {
  @description('Location name.')
  locationName: string
  @description('Failover priority for this location.')
  failoverPriority: int
  @description('Indicates whether the location is zone redundant.')
  isZoneRedundant: bool
}
