import { modelDeploymentInfo, raiPolicyInfo } from './ai_ml/ai-services.bicep'
import { identityInfo } from './security/managed-identity.bicep'

targetScope = 'subscription'

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
}

@description('Responsible AI policies for the Azure AI Services instance.')
param raiPolicies raiPolicyInfo[] = [
  {
    name: workloadName
    mode: 'Blocking'
    prompt: {}
    completion: {}
  }
]

@description('Model deployment for Azure OpenAI chat completion.')
param chatModelDeployment modelDeploymentInfo = {
  name: 'gpt-4o'
  model: { format: 'OpenAI', name: 'gpt-4o', version: '2024-11-20' }
  sku: { name: 'GlobalStandard', capacity: 10 }
  raiPolicyName: workloadName
  versionUpgradeOption: 'OnceCurrentVersionExpired'
}

@description('Identities to assign roles to.')
param identities identityInfo[] = []

var abbrs = loadJsonContent('./abbreviations.json')
var roles = loadJsonContent('./roles.json')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

resource contributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.general.contributor
}

var resourceGroupName = '${abbrs.managementGovernance.resourceGroup}${workloadName}'
resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: union(tags, {})
}

var contributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: contributorRole.id
    principalType: identity.principalType
  }
]

var resourceGroupRoleAssignmentName = '${resourceGroupName}-role'
module resourceGroupRoleAssignment './security/resource-group-role-assignment.bicep' = {
  name: resourceGroupRoleAssignmentName
  scope: resourceGroup
  params: {
    roleAssignments: concat(contributorIdentityAssignments, [])
  }
}

resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.security.keyVaultSecretsUser
}

var keyVaultSecretsUserIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: keyVaultSecretsUserRole.id
    principalType: identity.principalType
  }
]

var keyVaultName = '${abbrs.security.keyVault}${resourceToken}'
module keyVault './security/key-vault.bicep' = {
  name: keyVaultName
  scope: resourceGroup
  params: {
    name: keyVaultName
    location: location
    tags: union(tags, {})
    roleAssignments: concat(keyVaultSecretsUserIdentityAssignments, [])
  }
}

var logAnalyticsWorkspaceName = '${abbrs.managementGovernance.logAnalyticsWorkspace}${resourceToken}'
module logAnalyticsWorkspace './management_governance/log-analytics-workspace.bicep' = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: union(tags, {})
  }
}

var applicationInsightsName = '${abbrs.managementGovernance.applicationInsights}${resourceToken}'
module applicationInsights './management_governance/application-insights.bicep' = {
  name: applicationInsightsName
  scope: resourceGroup
  params: {
    name: applicationInsightsName
    location: location
    tags: union(tags, {})
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
}

resource cognitiveServicesUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesUser
}

resource cognitiveServicesOpenAIUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.cognitiveServicesOpenAIUser
}

var cognitiveServicesUserRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: cognitiveServicesUserRole.id
    principalType: identity.principalType
  }
]

var cognitiveServicesOpenAIUserRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: cognitiveServicesOpenAIUserRole.id
    principalType: identity.principalType
  }
]

var aiServicesName = '${abbrs.ai.aiServices}${resourceToken}'
module aiServices './ai_ml/ai-services.bicep' = {
  name: aiServicesName
  scope: resourceGroup
  params: {
    name: aiServicesName
    location: location
    tags: union(tags, {})
    raiPolicies: raiPolicies
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    deployments: [
      chatModelDeployment
    ]
    roleAssignments: concat(cognitiveServicesUserRoleAssignments, cognitiveServicesOpenAIUserRoleAssignments, [])
  }
}

// Require self-referencing role assignment for AI Services identity to access Azure OpenAI.
module aiServicesRoleAssignment './security/resource-role-assignment.json' = {
  name: '${aiServicesName}-role'
  scope: resourceGroup
  params: {
    resourceId: aiServices.outputs.id
    roleAssignments: [
      {
        principalId: aiServices.outputs.principalId
        roleDefinitionId: cognitiveServicesUserRole.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

// Required RBAC roles for Azure Functions to access the storage account
// https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference?tabs=blob&pivots=programming-language-python#connecting-to-host-storage-with-an-identity
resource storageAccountContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageAccountContributor
}

resource storageBlobDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageBlobDataContributor
}

resource storageBlobDataOwnerRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.storage.storageBlobDataOwner
}

resource storageFileDataPrivilegedContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageFileDataPrivilegedContributor
}

resource storageTableDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageTableDataContributor
}

resource storageQueueDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.storage.storageQueueDataContributor
}

var storageAccountContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageAccountContributorRole.id
    principalType: identity.principalType
  }
]

var storageBlobDataContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageBlobDataContributorRole.id
    principalType: identity.principalType
  }
]

var storageBlobDataOwnerIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageBlobDataOwnerRole.id
    principalType: identity.principalType
  }
]

var storageFileDataPrivilegedContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageFileDataPrivilegedContributorRole.id
    principalType: identity.principalType
  }
]

var storageTableDataContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageTableDataContributorRole.id
    principalType: identity.principalType
  }
]

var storageQueueDataContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageQueueDataContributorRole.id
    principalType: identity.principalType
  }
]

var storageAccountName = '${abbrs.storage.storageAccount}${resourceToken}'
module storageAccount './storage/storage-account.bicep' = {
  name: storageAccountName
  scope: resourceGroup
  params: {
    name: storageAccountName
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Standard_LRS'
    }
    roleAssignments: concat(
      storageAccountContributorIdentityAssignments,
      storageBlobDataContributorIdentityAssignments,
      storageBlobDataOwnerIdentityAssignments,
      storageFileDataPrivilegedContributorIdentityAssignments,
      storageTableDataContributorIdentityAssignments,
      storageQueueDataContributorIdentityAssignments,
      [
        {
          principalId: aiServices.outputs.principalId
          roleDefinitionId: storageBlobDataContributorRole.id
          principalType: 'ServicePrincipal'
        }
      ]
    )
  }
}

// DEMO: Create a container in the storage account for processing documents
var documentsContainerName = 'documents'
module documentsContainer 'storage/storage-blob-container.bicep' = {
  name: '${storageAccountName}-${documentsContainerName}'
  scope: resourceGroup
  params: {
    name: documentsContainerName
    storageAccountName: storageAccount.outputs.name
  }
}

resource acrPushRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.containers.acrPush
}

resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: resourceGroup
  name: roles.containers.acrPull
}

var acrPushIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: acrPushRole.id
    principalType: identity.principalType
  }
]

var acrPullIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: acrPullRole.id
    principalType: identity.principalType
  }
]

var containerRegistryName = '${abbrs.containers.containerRegistry}${resourceToken}'
module containerRegistry 'containers/container-registry.bicep' = {
  name: containerRegistryName
  scope: resourceGroup
  params: {
    name: containerRegistryName
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Standard'
    }
    adminUserEnabled: true
    roleAssignments: concat(acrPushIdentityAssignments, acrPullIdentityAssignments, [])
  }
}

var containerAppsEnvironmentName = '${abbrs.containers.containerAppsEnvironment}${resourceToken}'
module containerAppsEnvironment 'containers/container-apps-environment.bicep' = {
  name: containerAppsEnvironmentName
  scope: resourceGroup
  params: {
    name: containerAppsEnvironmentName
    location: location
    tags: union(tags, {})
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    applicationInsightsName: applicationInsights.outputs.name
  }
}

resource azureMLDataScientistRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.azureMLDataScientist
}

var azureMLDataScientistRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: azureMLDataScientistRole.id
    principalType: identity.principalType
  }
]

var aiHubName = '${abbrs.ai.aiHub}${resourceToken}'
module aiHub './ai_ml/ai-hub.bicep' = {
  name: aiHubName
  scope: resourceGroup
  params: {
    name: aiHubName
    friendlyName: 'Hub - Python AI Document Pipeline Sample'
    descriptionInfo: 'Generated by the AI Document Pipeline Python sample project'
    location: location
    tags: union(tags, {})
    storageAccountId: storageAccount.outputs.id
    keyVaultId: keyVault.outputs.id
    applicationInsightsId: applicationInsights.outputs.id
    containerRegistryId: containerRegistry.outputs.id
    aiServicesName: aiServices.outputs.name
    roleAssignments: concat(azureMLDataScientistRoleAssignments, [])
  }
}

var aiHubProjectName = '${abbrs.ai.aiHubProject}${resourceToken}'
module aiHubProject './ai_ml/ai-hub-project.bicep' = {
  name: aiHubProjectName
  scope: resourceGroup
  params: {
    name: aiHubProjectName
    friendlyName: 'Project - Python AI Document Pipeline Sample'
    descriptionInfo: 'Generated by the AI Document Pipeline Python sample project'
    location: location
    tags: union(tags, {})
    aiHubName: aiHub.outputs.name
    roleAssignments: concat(azureMLDataScientistRoleAssignments, [])
  }
}

output environmentInfo object = {
  workloadName: workloadName
  azureResourceGroup: resourceGroup.name
  azureLocation: resourceGroup.location
  containerRegistryName: containerRegistry.outputs.name
  azureAIServicesEndpoint: aiServices.outputs.endpoint
  azureOpenAIEndpoint: aiServices.outputs.openAIEndpoint
  azureOpenAIChatDeployment: chatModelDeployment.name
  azureStorageAccount: storageAccount.outputs.name
  documentsContainerName: documentsContainerName
}
