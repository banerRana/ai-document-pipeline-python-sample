targetScope = 'resourceGroup'

@minLength(1)
@maxLength(48)
@description('Name of the workload which is used to generate a short unique hash used in all resources.')
param workloadName string

@minLength(1)
@description('Primary location for all resources.')
param location string

@description('Tags for all resources.')
param tags object = {
  WorkloadName: workloadName
  Environment: 'Dev'
  ApplicationName: applicationName
}

@description('Name of the application.')
param applicationName string = 'ai-document-pipeline'

@description('Name of the container image.')
param containerImageName string

@description('Name of the Azure OpenAI completion model for the application. Default is gpt-4o.')
param chatModelDeployment string = 'gpt-4o'

@description('Name of the existing workload App Configuration Store where the application settings are stored. If left empty, the default name generated using Azure CAF best practices will be used.')
param appConfigName string = ''

@description('Name of the existing workload Container Registry. If left empty, the default name generated using Azure CAF best practices will be used.')
param containerRegistryName string = ''

@description('Name of the existing workload Application Insights resource. If left empty, the default name generated using Azure CAF best practices will be used.')
param applicationInsightsName string = ''

@description('Name of the existing workload Storage Account. If left empty, the default name generated using Azure CAF best practices will be used.')
param storageAccountName string = ''

@description('Name of the existing workload AI Services resource. If left empty, the default name generated using Azure CAF best practices will be used.')
param aiServicesName string = ''

@description('Name of the existing workload Container Apps Environment. If left empty, the default name generated using Azure CAF best practices will be used.')
param containerAppsEnvironmentName string = ''

// Variables

@description('List of recommended abbreviation prefixes for resources, as defined in https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations.')
var abbrs = loadJsonContent('../../abbreviations.json')

@description('List of built-in roles for Azure resources, as defined in https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles.')
var roles = loadJsonContent('../../roles.json')

@description('Resource token for the workload, used to generate unique names for shared resources.')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

@description('Resource token for the application, used to generate unique names for application-specific resources.')
var appResourceToken = toLower(uniqueString(subscription().id, workloadName, location, applicationName))

@description('Name of the existing App Configuration Store where the application settings are stored. If left empty, the default name generated using Azure CAF best practices will be used.')
var _appConfigName = !empty(appConfigName)
  ? appConfigName
  : '${abbrs.developerTools.appConfigurationStore}${resourceToken}'

@description('Name of the existing workload Container Registry. If left empty, the default name generated using Azure CAF best practices will be used.')
var _containerRegistryName = !empty(containerRegistryName)
  ? containerRegistryName
  : '${abbrs.containers.containerRegistry}${resourceToken}'

@description('Name of the existing workload Application Insights resource.')
var _applicationInsightsName = !empty(applicationInsightsName)
  ? applicationInsightsName
  : '${abbrs.managementGovernance.applicationInsights}${resourceToken}'

@description('Name of the existing workload Storage Account.')
var _storageAccountName = !empty(storageAccountName)
  ? storageAccountName
  : '${abbrs.storage.storageAccount}${resourceToken}'

@description('Name of the existing workload AI Services resource.')
var _aiServicesName = !empty(aiServicesName) ? aiServicesName : '${abbrs.ai.aiServices}${resourceToken}'

@description('Name of the existing workload Container Apps Environment.')
var _containerAppsEnvironmentName = !empty(containerAppsEnvironmentName)
  ? containerAppsEnvironmentName
  : '${abbrs.containers.containerAppsEnvironment}${resourceToken}'

@description('Name of the Container App for the application.')
var containerAppName = '${abbrs.containers.containerApp}${appResourceToken}'

@description('Name of the user-assigned managed identity for the application.')
var applicationManagedIdentityName = '${abbrs.security.managedIdentity}${containerAppName}'

@description('Application config key for the Azure Storage Queue connection string.')
var documentsConnectionStringVariableName = 'AZURE_STORAGE_QUEUES_CONNECTION_STRING'

@description('Name of the Container App secret for the Application Insights connection string.')
var applicationInsightsConnectionStringSecretName = 'applicationinsightsconnectionstring'

@description('Name of the Container App secret for the Application Insights instrumentation key.')
var applicationInsightsKeySecretName = 'applicationinsightskey'

@description('Name of the Azure Storage Queue for processing documents.')
var documentsQueueName = 'documents'

// Deployments

resource appConfigStoreRef 'Microsoft.AppConfiguration/configurationStores@2024-05-01' existing = {
  name: _appConfigName
}

resource containerRegistryRef 'Microsoft.ContainerRegistry/registries@2025-04-01' existing = {
  name: _containerRegistryName
}

resource applicationInsightsRef 'Microsoft.Insights/components@2020-02-02' existing = {
  name: _applicationInsightsName
}

resource storageAccountRef 'Microsoft.Storage/StorageAccounts@2024-01-01' existing = {
  name: _storageAccountName
}

resource aiServicesRef 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: _aiServicesName
}

resource containerAppsEnvironmentRef 'Microsoft.App/managedEnvironments@2025-01-01' existing = {
  name: _containerAppsEnvironmentName
}

module applicationManagedIdentity '../../security/managed-identity.bicep' = {
  name: applicationManagedIdentityName
  params: {
    name: applicationManagedIdentityName
    location: location
    tags: union(tags, {})
  }
}

resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roles.containers.acrPull
}

module containerRegistryIdentityRoleAssignment '../../security/resource-role-assignment.json' = {
  name: 'containerRegistryIdentityRoleAssignment'
  params: {
    resourceId: containerRegistryRef.id
    roleAssignments: [
      {
        principalId: applicationManagedIdentity.outputs.principalId
        roleDefinitionId: acrPullRole.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Required RBAC roles for Azure Functions to access the storage account
// https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference?tabs=blob&pivots=programming-language-python#connecting-to-host-storage-with-an-identity
resource storageAccountContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roles.storage.storageAccountContributor
}

resource storageBlobDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roles.storage.storageBlobDataContributor
}

resource storageBlobDataOwnerRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roles.storage.storageBlobDataOwner
}

resource storageFileDataPrivilegedContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roles.storage.storageFileDataPrivilegedContributor
}

resource storageTableDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roles.storage.storageTableDataContributor
}

resource storageQueueDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roles.storage.storageQueueDataContributor
}

module storageAccountIdentityRoleAssignment '../../security/resource-role-assignment.json' = {
  name: 'storageAccountIdentityRoleAssignment'
  params: {
    resourceId: storageAccountRef.id
    roleAssignments: [
      {
        principalId: applicationManagedIdentity.outputs.principalId
        roleDefinitionId: storageAccountContributorRole.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: applicationManagedIdentity.outputs.principalId
        roleDefinitionId: storageBlobDataContributorRole.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: applicationManagedIdentity.outputs.principalId
        roleDefinitionId: storageBlobDataOwnerRole.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: applicationManagedIdentity.outputs.principalId
        roleDefinitionId: storageFileDataPrivilegedContributorRole.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: applicationManagedIdentity.outputs.principalId
        roleDefinitionId: storageTableDataContributorRole.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: applicationManagedIdentity.outputs.principalId
        roleDefinitionId: storageQueueDataContributorRole.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

resource cognitiveServicesUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roles.ai.cognitiveServicesUser
}

resource cognitiveServicesOpenAIUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roles.ai.cognitiveServicesOpenAIUser
}

resource appConfigDataOwnerRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: roles.integration.appConfigurationDataOwner
}

module aiServicesIdentityRoleAssignment '../../security/resource-role-assignment.json' = {
  name: 'aiServicesIdentityRoleAssignment'
  params: {
    resourceId: aiServicesRef.id
    roleAssignments: [
      {
        principalId: applicationManagedIdentity.outputs.principalId
        roleDefinitionId: appConfigDataOwnerRole.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: applicationManagedIdentity.outputs.principalId
        roleDefinitionId: cognitiveServicesUserRole.id
        principalType: 'ServicePrincipal'
      }
      {
        principalId: applicationManagedIdentity.outputs.principalId
        roleDefinitionId: cognitiveServicesOpenAIUserRole.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

module documentsQueue '../../storage/storage-queue.bicep' = {
  name: '${abbrs.storage.storageAccount}${resourceToken}-${documentsQueueName}'
  params: {
    name: documentsQueueName
    storageAccountName: storageAccountRef.name
  }
}

module containerApp '../../containers/container-app.bicep' = {
  name: containerAppName
  params: {
    name: containerAppName
    location: location
    tags: union(tags, { App: applicationName })
    containerAppsEnvironmentId: containerAppsEnvironmentRef.id
    containerAppIdentityId: applicationManagedIdentity.outputs.id
    imageInContainerRegistry: true
    containerRegistryName: containerRegistryRef.name
    containerImageName: containerImageName
    containerIngress: {
      external: true
      targetPort: 80
      transport: 'auto'
      allowInsecure: false
    }
    containerScale: {
      minReplicas: 1
      maxReplicas: 3
      rules: [
        {
          name: 'http'
          http: {
            metadata: {
              concurrentRequests: '20'
            }
          }
        }
      ]
    }
    secrets: [
      {
        name: applicationInsightsConnectionStringSecretName
        value: applicationInsightsRef.properties.ConnectionString
      }
      {
        name: applicationInsightsKeySecretName
        value: applicationInsightsRef.properties.InstrumentationKey
      }
    ]
    environmentVariables: [
      {
        name: 'AzureWebJobsFeatureFlags'
        value: 'EnableWorkerIndexing'
      }
      {
        name: 'FUNCTIONS_EXTENSION_VERSION'
        value: '~4'
      }
      {
        name: 'FUNCTIONS_WORKER_RUNTIME'
        value: 'python'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        secretRef: applicationInsightsConnectionStringSecretName
      }
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        secretRef: applicationInsightsKeySecretName
      }
      {
        name: 'ApplicationInsights_InstrumentationKey'
        secretRef: applicationInsightsKeySecretName
      }
      {
        name: 'AZURE_APPCONFIG_URL'
        value: 'https://${appConfigStoreRef.name}.azconfig.io'
      }
      {
        name: '$AzureWebJobsStorage__accountName'
        value: storageAccountRef.name
      }
      {
        name: '$AzureWebJobsStorage__credential'
        value: 'managedidentity'
      }
      {
        name: '$AzureWebJobsStorage__clientId'
        value: applicationManagedIdentity.outputs.clientId
      }
      {
        name: 'AZURE_CLIENT_ID'
        value: applicationManagedIdentity.outputs.clientId
      }
      {
        name: 'AZURE_TENANT_ID'
        value: subscription().tenantId
      }
      {
        name: 'AZURE_AISERVICES_ENDPOINT'
        value: aiServicesRef.properties.endpoint
      }
      {
        name: 'AZURE_OPENAI_ENDPOINT'
        value: aiServicesRef.properties.endpoint
      }
      {
        name: 'AZURE_OPENAI_CHAT_DEPLOYMENT'
        value: chatModelDeployment
      }
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccountRef.name
      }
      {
        name: '${documentsConnectionStringVariableName}__accountName'
        value: storageAccountRef.name
      }
      {
        name: '${documentsConnectionStringVariableName}__credential'
        value: 'managedidentity'
      }
      {
        name: '${documentsConnectionStringVariableName}__clientId'
        value: applicationManagedIdentity.outputs.clientId
      }
      {
        name: 'WEBSITE_HOSTNAME'
        value: 'localhost'
      }
      {
        name: 'LOGLEVEL'
        value: 'INFO'
      }
      {
        name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
        value: '7'
      }
      {
        name: 'WEBSITE_VNET_ROUTE_ALL'
        value: '0'
      }
      {
        name: 'allow_environment_variables'
        value: 'true'
      }
    ]
  }
}

// Outputs

@description('Details of the deployed Container App resource, including ID, name, FQDN, and URL.')
output appInfo object = {
  id: containerApp.outputs.id
  name: containerApp.outputs.name
  fqdn: containerApp.outputs.fqdn
  url: containerApp.outputs.url
  latestRevisionFqdn: containerApp.outputs.latestRevisionFqdn
  latestRevisionUrl: containerApp.outputs.latestRevisionUrl
}
