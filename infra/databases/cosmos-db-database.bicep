@description('Name of the resource.')
param name string
@description('Tags for the resource.')
param tags object = {}

@description('Name of the Cosmos DB account.')
param cosmosDbName string
@description('List of containers to create in the database.')
param containers containerInfo[] = []

// Deployments

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' existing = {
  name: cosmosDbName
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-12-01-preview' = {
  parent: cosmosDb
  name: name
  tags: tags
  properties: {
    resource: {
      id: name
    }
  }
}

resource databaseContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-12-01-preview' = [
  for container in containers: {
    parent: database
    name: container.name
    tags: tags
    properties: {
      resource: container.resource
      options: container.options
    }
  }
]

// Outputs

@description('ID for the deployed Cosmos DB database resource.')
output id string = database.id
@description('Name for the deployed Cosmos DB database resource.')
output name string = database.name

// Definitions

@export()
@description('Container information for a database container.')
type containerInfo = {
  @description('Name of the container.')
  name: string
  @description('Definition of the resource.')
  resource: object
  @description('Definition of the options.')
  options: object
}
