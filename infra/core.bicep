import { resourceGroupScope } from './helpers.bicep'
import { modelDeploymentInfo, raiPolicyInfo } from './ai_ml/ai-services.bicep'
import { identityInfo } from './security/managed-identity.bicep'
import { vnetConfigInfo } from './containers/container-apps-environment.bicep'

targetScope = 'subscription'

@description('Environment name used as a tag for all resources. This is directly mapped to the azd-environment.')
param environmentName string = ''

@minLength(1)
@maxLength(48)
@description('Name of the workload which is used to generate a short unique hash used in all resources.')
param workloadName string

@minLength(1)
@description('Primary location for all resources.')
param location string

@description('Tags for all resources. Define your tagging strategy using https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging.')
param tags object = {
  'azd-env-name': environmentName
  WorkloadName: workloadName
  Environment: 'Dev'
}

@description('Name of the application. Defaults to ai-document-pipeline.')
param applicationName string = 'ai-document-pipeline'

@description('Configuration for Azure resources to reuse for the deployment.')
param azureReuseConfig object = {}

@description('Name of the Resource Group to deploy the resources. If left empty, a name will be generated using Azure CAF best practices.')
param resourceGroupName string = ''

@description('Principal ID of the user to assign roles to. This is used for the role assignments in the resource group and other resources.')
param principalId string = ''

@description('Identities to assign roles to.')
param identities identityInfo[] = union([], [
  {
    principalId: principalId
    principalType: 'User'
  }
])

@description('Whether to deploy the resources in a network isolated environment. Defaults to false.')
param networkIsolation bool = false

@description('Whether to deploy the VPN gateway to access the network isolated environment in the zero trust configuration. Defaults to false.')
param deployVPN bool = false

@description('Name of the VPN Gateway. If left empty, a name will be generated using Azure CAF best practices.')
param vpnGatewayName string = ''

@description('Name of the VPN Gateway public IP address. If left empty, a name will be generated using Azure CAF best practices.')
param vpnGatewayPublicIpName string = ''

@description('Whether to deploy the Bastion host VM to access the network isolated environment in the zero trust configuration. Defaults to true.')
param deployVM bool = true

@description('Name of the Bastion host VM. If left empty, a name will be generated using Azure CAF best practices.')
param vmName string = ''

@description('Username for the Bastion host VM when deploying with networkIsolation true.')
param vmUserName string?

@minLength(6)
@maxLength(72)
@description('User password for the Bastion host VM when deploying with networkIsolation true. Password must satisfy at least 3 of password complexity requirements from the following: 1-Contains an uppercase character, 2-Contains a lowercase character, 3-Contains a numeric digit, 4-Contains a special character, 5- Control characters are not allowed.')
@secure()
param vmUserInitialPassword string?

@description('Name of the Key Vault secret to store the VM user password. Defaults to vmUserInitialPassword.')
param vmUserPasswordKeyVaultSecretName string = 'vmUserInitialPassword'

@description('Name of the Virtual Network to deploy the resources. If left empty, a name will be generated using Azure CAF best practices.')
param vnetName string = ''

@description('Address space for the Virtual Network. Defaults to 10.0.0.0/23.')
param vnetAddress string = '10.0.0.0/23'

@description('Name of the network security group for the AI services. If left empty, a name will be generated using Azure CAF best practices.')
param aiNsgName string = ''

@description('Name of the subnet for the AI services. If left empty, a name will be generated using Azure CAF best practices.')
param aiSubnetName string = ''

@description('Address prefix for the AI services subnet. Defaults to 10.0.0.0/26.')
param aiSubnetPrefix string = '10.0.0.0/26'

@description('Name of the network security group for the Azure Container Apps environment. If left empty, a name will be generated using Azure CAF best practices.')
param acaNsgName string = ''

@description('Name of the subnet for the Azure Container Apps environment. If left empty, a name will be generated using Azure CAF best practices.')
param acaSubnetName string = ''

@description('Address prefix for the Azure Container Apps environment subnet. Defaults to 10.0.1.64/26.')
param acaSubnetPrefix string = '10.0.1.64/26'

@description('Name of the network security group for the Bastion host VM. If left empty, a name will be generated using Azure CAF best practices.')
param bastionNsgName string = ''

@description('Name of the Key Vault to store Bastion host VM secrets. If left empty, a name will be generated using Azure CAF best practices.')
param bastionKeyVaultName string = ''

@description('Address prefix for the Bastion host VM subnet. Defaults to 10.0.0.64/26.')
param bastionSubnetPrefix string = '10.0.0.64/26'

@description('Name of the network security group for the Azure Cosmos DB. If left empty, a name will be generated using Azure CAF best practices.')
param databaseNsgName string = ''

@description('Name of the subnet for Azure Cosmos DB. If left empty, a name will be generated using Azure CAF best practices.')
param databaseSubnetName string = ''

@description('Address prefix for the Azure Cosmos DB subnet. Defaults to 10.0.1.0/26.')
param databaseSubnetPrefix string = '10.0.1.0/26'

@description('Name of the Private Endpoint for Azure Storage Blob Service. If left empty, a name will be generated using Azure CAF best practices.')
param azureBlobStorageAccountPe string = ''

@description('Name of the Private Endpoint for Azure Storage Table Service. If left empty, a name will be generated using Azure CAF best practices.')
param azureTableStorageAccountPe string = ''

@description('Name of the Private Endpoint for Azure Storage Queue Service. If left empty, a name will be generated using Azure CAF best practices.')
param azureQueueStorageAccountPe string = ''

@description('Name of the Private Endpoint for Azure Storage File Service. If left empty, a name will be generated using Azure CAF best practices.')
param azureFileStorageAccountPe string = ''

@description('Name of the Private Endpoint for Azure Cosmos DB. If left empty, a name will be generated using Azure CAF best practices.')
param azureCosmosDbAccountPe string = ''

@description('Name of the Private Endpoint for Azure Key Vault. If left empty, a name will be generated using Azure CAF best practices.')
param keyVaultPe string = ''

@description('Name of the Private Endpoint for Azure App Configuration. If left empty, a name will be generated using Azure CAF best practices.')
param appConfigPe string = ''

@description('Name of the Private Link for Azure Monitor. If left empty, a name will be generated using Azure CAF best practices.')
param azureMonitorPrivateLinkName string = ''

@description('Name of the Private Endpoint for Log Analytics Workspace. If left empty, a name will be generated using Azure CAF best practices.')
param logAnalyticsPe string = ''

@description('Name of the Log Analytics Workspace to store logs and metrics. If left empty, a name will be generated using Azure CAF best practices.')
param logAnalyticsWorkspaceName string = ''

@description('Name of the Application Insights instance to monitor the application. If left empty, a name will be generated using Azure CAF best practices.')
param applicationInsightsName string = ''

@description('Name of the Private Endpoint for Azure AI Services. If left empty, a name will be generated using Azure CAF best practices.')
param aiServicesPe string = ''

@description('Name of the Private Endpoint for Azure Container Registry. If left empty, a name will be generated using Azure CAF best practices.')
param containerRegistryPe string = ''

@description('Name of the Azure Container Registry to store application images. If left empty, a name will be generated using Azure CAF best practices.')
param containerRegistryName string = ''

@description('Name of the Azure Container Apps environment to deploy the application. If left empty, a name will be generated using Azure CAF best practices.')
param containerAppsEnvironmentName string = ''

@description('Name of the Private Endpoint for Azure Container Apps environment. If left empty, a name will be generated using Azure CAF best practices.')
param containerAppsEnvironmentPe string = ''

@description('Name of the App Configuration Store to store application settings. If left empty, a name will be generated using Azure CAF best practices.')
param appConfigName string = ''

@description('Whether to deploy app config values to Azure App Configuration. Defaults to true.')
param deployAppConfigValues bool = true

@description('Name of the Azure Cosmos DB account to store application data. If left empty, a name will be generated using Azure CAF best practices.')
param azureCosmosDbName string = ''

@description('Name of the Azure Cosmos DB database to create in the account. If left empty, a name will be generated using Azure CAF best practices.')
param azureCosmosDatabaseName string = ''

@description('Name of the Azure AI services instance. If left empty, a name will be generated using Azure CAF best practices.')
param aiServicesName string = ''

@description('Name of the Azure OpenAI completion model for the application. Default is gpt-4o.')
param chatModelDeploymentModel string = 'gpt-4o'

@description('Model deployment for Azure OpenAI chat completion.')
param chatModelDeployment modelDeploymentInfo = {
  name: chatModelDeploymentModel
  model: { format: 'OpenAI', name: 'gpt-4o', version: '2024-11-20' }
  sku: { name: 'GlobalStandard', capacity: 10 }
  raiPolicyName: workloadName
  versionUpgradeOption: 'OnceCurrentVersionExpired'
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

@description('API version for the Azure OpenAI Service. Defaults to 2025-03-01-preview.')
param openaiApiVersion string = '2025-03-01-preview'

@description('Name of the Azure Storage account to store application data. If left empty, a name will be generated using Azure CAF best practices.')
param storageAccountName string = ''

@description('Name of the Azure Storage blob container to store documents to process. Defaults to documents.')
param storageContainerName string = 'documents'

@description('Name of the Azure Key Vault to store application secrets. If left empty, a name will be generated using Azure CAF best practices.')
param keyVaultName string = ''

@description('Name of the Private Endpoint for Azure AI Foundry Hub. If left empty, a name will be generated using Azure CAF best practices.')
param aiHubPe string = ''

@description('Name of the Azure AI Foundry Hub to manage resources for AI projects. If left empty, a name will be generated using Azure CAF best practices.')
param aiHubName string = ''

@description('Name of the Azure AI Foundry Hub project to build, test, and deploy AI capabilities. If left empty, a name will be generated using Azure CAF best practices.')
param aiHubProjectName string = ''

// Variables

@description('Map of Azure cloud environments to their respective audience IDs.')
var audienceMap = {
  AzureCloud: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
  AzureUSGovernment: '51bb15d4-3a4f-4ebf-9dca-40096fe32426'
  AzureGermanCloud: '538ee9e6-310a-468d-afef-ea97365856a9'
  AzureChinaCloud: '49f817b6-84ae-4cc0-928c-73f27289b3aa'
}

@description('Tenant ID for the Azure subscription being deployed to.')
var tenantId = subscription().tenantId

@description('The Azure cloud environment in which the deployment is taking place.')
var cloud = environment().name

@description('The audience ID for the Azure cloud environment.')
var audience = audienceMap[cloud]

@description('The login endpoint for the Azure cloud environment.')
var tenant = uri(environment().authentication.loginEndpoint, tenantId)

@description('The issuer URL for the Azure cloud environment.')
var issuer = 'https://sts.windows.net/${tenantId}/'

@description('List of recommended abbreviation prefixes for resources, as defined in https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations.')
var abbrs = loadJsonContent('./abbreviations.json')

@description('List of built-in roles for Azure resources, as defined in https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles.')
var roles = loadJsonContent('./roles.json')

@description('Resource token for the workload, used to generate unique names for shared resources.')
var resourceToken = toLower(uniqueString(subscription().id, workloadName, location))

@description('Default configuration for Azure resources to reuse for the deployment.')
var azureReuseConfigDefaults = {
  containerRegistryReuse: false
  existingContainerRegistryResourceGroupName: ''
  existingContainerRegistryName: ''
  logAnalyticsWorkspaceReuse: false
  existingLogAnalyticsWorkspaceResourceGroupName: ''
  existingLogAnalyticsWorkspaceName: ''
  appInsightsReuse: false
  existingAppInsightsResourceGroupName: ''
  existingAppInsightsName: ''
  aiServicesReuse: false
  existingAiServicesResourceGroupName: ''
  existingAiServicesName: ''
  cosmosDbReuse: false
  existingCosmosDbResourceGroupName: ''
  existingCosmosDbAccountName: ''
  existingCosmosDbDatabaseName: ''
  keyVaultReuse: false
  existingKeyVaultResourceGroupName: ''
  existingKeyVaultName: ''
  storageReuse: false
  existingStorageResourceGroupName: ''
  existingStorageName: ''
  vnetReuse: false
  existingVnetResourceGroupName: ''
  existingVnetName: ''
  appConfigReuse: false
  existingAppConfigResourceGroupName: ''
  existingAppConfigName: ''
  containerAppsEnvironmentReuse: false
  existingContainerAppsEnvironmentResourceGroupName: ''
  existingContainerAppsEnvironmentName: ''
  aiHubReuse: false
  existingAiHubResourceGroupName: ''
  existingAiHubName: ''
  existingAiHubProjectName: ''
}

@description('Configuration for Azure resources to reuse for the deployment.')
var _azureReuseConfig = union(azureReuseConfigDefaults, {
  containerRegistryReuse: (empty(azureReuseConfig.containerRegistryReuse)
    ? azureReuseConfigDefaults.containerRegistryReuse
    : toLower(azureReuseConfig.containerRegistryReuse) == 'true')
  existingContainerRegistryResourceGroupName: (empty(azureReuseConfig.existingContainerRegistryResourceGroupName)
    ? azureReuseConfigDefaults.existingContainerRegistryResourceGroupName
    : azureReuseConfig.existingContainerRegistryResourceGroupName)
  existingContainerRegistryName: (empty(azureReuseConfig.existingContainerRegistryName)
    ? azureReuseConfigDefaults.existingContainerRegistryName
    : azureReuseConfig.existingContainerRegistryName)
  logAnalyticsWorkspaceReuse: (empty(azureReuseConfig.logAnalyticsWorkspaceReuse)
    ? azureReuseConfigDefaults.logAnalyticsWorkspaceReuse
    : toLower(azureReuseConfig.logAnalyticsWorkspaceReuse) == 'true')
  existingLogAnalyticsWorkspaceResourceGroupName: (empty(azureReuseConfig.existingLogAnalyticsWorkspaceResourceGroupName)
    ? azureReuseConfigDefaults.existingLogAnalyticsWorkspaceResourceGroupName
    : azureReuseConfig.existingLogAnalyticsWorkspaceResourceGroupName)
  existingLogAnalyticsWorkspaceName: (empty(azureReuseConfig.existingLogAnalyticsWorkspaceName)
    ? azureReuseConfigDefaults.existingLogAnalyticsWorkspaceName
    : azureReuseConfig.existingLogAnalyticsWorkspaceName)
  appInsightsReuse: (empty(azureReuseConfig.appInsightsReuse)
    ? azureReuseConfigDefaults.appInsightsReuse
    : toLower(azureReuseConfig.appInsightsReuse) == 'true')
  existingAppInsightsResourceGroupName: (empty(azureReuseConfig.existingAppInsightsResourceGroupName)
    ? azureReuseConfigDefaults.existingAppInsightsResourceGroupName
    : azureReuseConfig.existingAppInsightsResourceGroupName)
  existingAppInsightsName: (empty(azureReuseConfig.existingAppInsightsName)
    ? azureReuseConfigDefaults.existingAppInsightsName
    : azureReuseConfig.existingAppInsightsName)
  aiServicesReuse: (empty(azureReuseConfig.aiServicesReuse)
    ? azureReuseConfigDefaults.aiServicesReuse
    : toLower(azureReuseConfig.aiServicesReuse) == 'true')
  existingAiServicesResourceGroupName: (empty(azureReuseConfig.existingAiServicesResourceGroupName)
    ? azureReuseConfigDefaults.existingAiServicesResourceGroupName
    : azureReuseConfig.existingAiServicesResourceGroupName)
  existingAiServicesName: (empty(azureReuseConfig.existingAiServicesName)
    ? azureReuseConfigDefaults.existingAiServicesName
    : azureReuseConfig.existingAiServicesName)
  cosmosDbReuse: (empty(azureReuseConfig.cosmosDbReuse)
    ? azureReuseConfigDefaults.cosmosDbReuse
    : toLower(azureReuseConfig.cosmosDbReuse) == 'true')
  existingCosmosDbResourceGroupName: (empty(azureReuseConfig.existingCosmosDbResourceGroupName)
    ? azureReuseConfigDefaults.existingCosmosDbResourceGroupName
    : azureReuseConfig.existingCosmosDbResourceGroupName)
  existingCosmosDbAccountName: (empty(azureReuseConfig.existingCosmosDbAccountName)
    ? azureReuseConfigDefaults.existingCosmosDbAccountName
    : azureReuseConfig.existingCosmosDbAccountName)
  existingCosmosDbDatabaseName: (empty(azureReuseConfig.existingCosmosDbDatabaseName)
    ? azureReuseConfigDefaults.existingCosmosDbDatabaseName
    : azureReuseConfig.existingCosmosDbDatabaseName)
  keyVaultReuse: (empty(azureReuseConfig.keyVaultReuse)
    ? azureReuseConfigDefaults.keyVaultReuse
    : toLower(azureReuseConfig.keyVaultReuse) == 'true')
  existingKeyVaultResourceGroupName: (empty(azureReuseConfig.existingKeyVaultResourceGroupName)
    ? azureReuseConfigDefaults.existingKeyVaultResourceGroupName
    : azureReuseConfig.existingKeyVaultResourceGroupName)
  existingKeyVaultName: (empty(azureReuseConfig.existingKeyVaultName)
    ? azureReuseConfigDefaults.existingKeyVaultName
    : azureReuseConfig.existingKeyVaultName)
  storageReuse: (empty(azureReuseConfig.storageReuse)
    ? azureReuseConfigDefaults.storageReuse
    : toLower(azureReuseConfig.storageReuse) == 'true')
  existingStorageResourceGroupName: (empty(azureReuseConfig.existingStorageResourceGroupName)
    ? azureReuseConfigDefaults.existingStorageResourceGroupName
    : azureReuseConfig.existingStorageResourceGroupName)
  existingStorageName: (empty(azureReuseConfig.existingStorageName)
    ? azureReuseConfigDefaults.existingStorageName
    : azureReuseConfig.existingStorageName)
  vnetReuse: (empty(azureReuseConfig.vnetReuse)
    ? azureReuseConfigDefaults.vnetReuse
    : toLower(azureReuseConfig.vnetReuse) == 'true')
  existingVnetResourceGroupName: (empty(azureReuseConfig.existingVnetResourceGroupName)
    ? azureReuseConfigDefaults.existingVnetResourceGroupName
    : azureReuseConfig.existingVnetResourceGroupName)
  existingVnetName: (empty(azureReuseConfig.existingVnetName)
    ? azureReuseConfigDefaults.existingVnetName
    : azureReuseConfig.existingVnetName)
  appConfigReuse: (empty(azureReuseConfig.appConfigReuse)
    ? azureReuseConfigDefaults.appConfigReuse
    : toLower(azureReuseConfig.appConfigReuse) == 'true')
  existingAppConfigResourceGroupName: (empty(azureReuseConfig.existingAppConfigResourceGroupName)
    ? azureReuseConfigDefaults.existingAppConfigResourceGroupName
    : azureReuseConfig.existingAppConfigResourceGroupName)
  existingAppConfigName: (empty(azureReuseConfig.existingAppConfigName)
    ? azureReuseConfigDefaults.existingAppConfigName
    : azureReuseConfig.existingAppConfigName)
  containerAppsEnvironmentReuse: (empty(azureReuseConfig.containerAppsEnvironmentReuse)
    ? azureReuseConfigDefaults.containerAppsEnvironmentReuse
    : toLower(azureReuseConfig.containerAppsEnvironmentReuse) == 'true')
  existingContainerAppsEnvironmentResourceGroupName: (empty(azureReuseConfig.existingContainerAppsEnvironmentResourceGroupName)
    ? azureReuseConfigDefaults.existingContainerAppsEnvironmentResourceGroupName
    : azureReuseConfig.existingContainerAppsEnvironmentResourceGroupName)
  existingContainerAppsEnvironmentName: (empty(azureReuseConfig.existingContainerAppsEnvironmentName)
    ? azureReuseConfigDefaults.existingContainerAppsEnvironmentName
    : azureReuseConfig.existingContainerAppsEnvironmentName)
  aiHubReuse: (empty(azureReuseConfig.aiHubReuse)
    ? azureReuseConfigDefaults.aiHubReuse
    : toLower(azureReuseConfig.aiHubReuse) == 'true')
  existingAiHubResourceGroupName: (empty(azureReuseConfig.existingAiHubResourceGroupName)
    ? azureReuseConfigDefaults.existingAiHubResourceGroupName
    : azureReuseConfig.existingAiHubResourceGroupName)
  existingAiHubName: (empty(azureReuseConfig.existingAiHubName)
    ? azureReuseConfigDefaults.existingAiHubName
    : azureReuseConfig.existingAiHubName)
  existingAiHubProjectName: (empty(azureReuseConfig.existingAiHubProjectName)
    ? azureReuseConfigDefaults.existingAiHubProjectName
    : azureReuseConfig.existingAiHubProjectName)
})

@description('Name of the Resource Group to deploy the resources. If left empty, a name will be generated using Azure CAF best practices.')
var _resourceGroupName = !empty(resourceGroupName)
  ? resourceGroupName
  : '${abbrs.managementGovernance.resourceGroup}${workloadName}'

@description('Name of the VPN Gateway. If left empty, a name will be generated using Azure CAF best practices.')
var _vpnGatewayName = !empty(vpnGatewayName) ? vpnGatewayName : '${abbrs.security.vpnGateway}${resourceToken}'

@description('Name of the VPN Gateway public IP address. If left empty, a name will be generated using Azure CAF best practices.')
var _vpnGatewayPublicIpName = !empty(vpnGatewayPublicIpName)
  ? vpnGatewayPublicIpName
  : '${abbrs.networking.publicIPAddress}${abbrs.security.vpnGateway}${resourceToken}'

@description('Name of the Bastion host VM. If left empty, a name will be generated using Azure CAF best practices.')
var _vmName = !empty(vmName) ? vmName : '${abbrs.compute.virtualMachine}${resourceToken}'

@description('Username for the Bastion host VM when deploying with networkIsolation true.')
var _vmUserName = !empty(vmUserName) ? vmUserName : 'vmuser'

@description('Name of the Key Vault secret to store the VM user password. Defaults to vmUserInitialPassword.')
var _vmUserPasswordKeyVaultSecretName = !empty(vmUserPasswordKeyVaultSecretName)
  ? vmUserPasswordKeyVaultSecretName
  : 'vmUserInitialPassword'

@description('Name of the Bastion host when deploying with networkIsolation true, using Azure CAF best practices.')
var bastionHostName = '${abbrs.security.bastion}${_vmName}'

@description('Name of the Bastion host public IP address when deploying with networkIsolation true, using Azure CAF best practices.')
var bastionHostPublicIpName = '${abbrs.networking.publicIPAddress}${bastionHostName}'

@description('Name of the Key Vault to store Bastion host VM secrets. If left empty, a name will be generated using Azure CAF best practices.')
var _bastionKeyVaultName = !empty(bastionKeyVaultName)
  ? bastionKeyVaultName
  : '${abbrs.security.keyVault}${abbrs.compute.virtualMachine}${resourceToken}'

@description('Name of the VM NIC when deploying with networkIsolation true, using Azure CAF best practices.')
var vmNicName = '${abbrs.networking.networkInterface}${_vmName}'

@description('Name of the VM OS disk when deploying with networkIsolation true, using Azure CAF best practices.')
var vmOSDiskName = '${abbrs.compute.managedDiskOS}${_vmName}'

@description('Name of the VM managed identity when deploying with networkIsolation true, using Azure CAF best practices.')
var vmManagedIdentityName = '${abbrs.security.managedIdentity}${_vmName}'

@description('Whether to reuse an existing Virtual Network as defined in the azureReuseConfig parameter. Defaults to false.')
var _vnetReuse = _azureReuseConfig.vnetReuse

@description('Name of the Virtual Network to deploy the resources. If left empty, a name will be generated using Azure CAF best practices.')
var _vnetName = _azureReuseConfig.vnetReuse
  ? _azureReuseConfig.existingVnetName
  : !empty(vnetName) ? vnetName : '${abbrs.networking.virtualNetwork}${resourceToken}'

@description('Address space for the Virtual Network. Defaults to 10.0.0.0/23.')
var _vnetAddress = !empty(vnetAddress) ? vnetAddress : '10.0.0.0/23'

@description('Name of the network security group for the AI services. If left empty, a name will be generated using Azure CAF best practices.')
var _aiNsgName = !empty(aiNsgName)
  ? aiNsgName
  : '${abbrs.networking.networkSecurityGroup}${abbrs.ai.aiServices}${resourceToken}'

@description('Name of the subnet for the AI services. If left empty, a name will be generated using Azure CAF best practices.')
var _aiSubnetName = !empty(aiSubnetName)
  ? aiSubnetName
  : '${abbrs.networking.virtualNetworkSubnet}${abbrs.ai.aiServices}${resourceToken}'

@description('Address prefix for the AI services subnet. Defaults to 10.0.0.0/26.')
var _aiSubnetPrefix = !empty(aiSubnetPrefix) ? aiSubnetPrefix : '10.0.0.0/26'

@description('Name of the network security group for the Azure Container Apps environment. If left empty, a name will be generated using Azure CAF best practices.')
var _acaNsgName = !empty(acaNsgName)
  ? acaNsgName
  : '${abbrs.networking.networkSecurityGroup}${abbrs.containers.containerAppsEnvironment}${resourceToken}'

@description('Name of the subnet for the Azure Container Apps environment. If left empty, a name will be generated using Azure CAF best practices.')
var _acaSubnetName = !empty(acaSubnetName)
  ? acaSubnetName
  : '${abbrs.networking.virtualNetworkSubnet}${abbrs.containers.containerAppsEnvironment}${resourceToken}'

@description('Address prefix for the Azure Container Apps environment subnet. Defaults to 10.0.1.64/26.')
var _acaSubnetPrefix = !empty(acaSubnetPrefix) ? acaSubnetPrefix : '10.0.1.64/26'

@description('Name of the network security group for the Bastion host VM. If left empty, a name will be generated using Azure CAF best practices.')
var _bastionNsgName = !empty(bastionNsgName)
  ? bastionNsgName
  : '${abbrs.networking.networkSecurityGroup}${abbrs.security.bastion}${resourceToken}'

@description('Address prefix for the Bastion host VM subnet. Defaults to 10.0.0.64/26.')
var _bastionSubnetPrefix = !empty(bastionSubnetPrefix) ? bastionSubnetPrefix : '10.0.0.64/26'

@description('Name of the network security group for the Azure Cosmos DB. If left empty, a name will be generated using Azure CAF best practices.')
var _databaseNsgName = !empty(databaseNsgName)
  ? databaseNsgName
  : '${abbrs.networking.networkSecurityGroup}${abbrs.databases.cosmosDBTable}${resourceToken}'

@description('Name of the subnet for Azure Cosmos DB. If left empty, a name will be generated using Azure CAF best practices.')
var _databaseSubnetName = !empty(databaseSubnetName)
  ? databaseSubnetName
  : '${abbrs.networking.virtualNetworkSubnet}${abbrs.databases.cosmosDBTable}${resourceToken}'

@description('Address prefix for the Azure Cosmos DB subnet. Defaults to 10.0.1.0/26.')
var _databaseSubnetPrefix = !empty(databaseSubnetPrefix) ? databaseSubnetPrefix : '10.0.1.0/26'

@description('Name of the Private Endpoint for Azure Storage Blob Service. If left empty, a name will be generated using Azure CAF best practices.')
var _azureBlobStorageAccountPe = !empty(azureBlobStorageAccountPe)
  ? azureBlobStorageAccountPe
  : '${abbrs.networking.privateEndpoint}${abbrs.storage.storageAccount}${resourceToken}-blob'

@description('Name of the Private Endpoint for Azure Storage Table Service. If left empty, a name will be generated using Azure CAF best practices.')
var _azureTableStorageAccountPe = !empty(azureTableStorageAccountPe)
  ? azureTableStorageAccountPe
  : '${abbrs.networking.privateEndpoint}${abbrs.storage.storageAccount}${resourceToken}-table'

@description('Name of the Private Endpoint for Azure Storage Queue Service. If left empty, a name will be generated using Azure CAF best practices.')
var _azureQueueStorageAccountPe = !empty(azureQueueStorageAccountPe)
  ? azureQueueStorageAccountPe
  : '${abbrs.networking.privateEndpoint}${abbrs.storage.storageAccount}${resourceToken}-queue'

@description('Name of the Private Endpoint for Azure Storage File Service. If left empty, a name will be generated using Azure CAF best practices.')
var _azureFileStorageAccountPe = !empty(azureFileStorageAccountPe)
  ? azureFileStorageAccountPe
  : '${abbrs.networking.privateEndpoint}${abbrs.storage.storageAccount}${resourceToken}-file'

@description('Name of the Private Endpoint for Azure Cosmos DB. If left empty, a name will be generated using Azure CAF best practices.')
var _azureCosmosDbAccountPe = !empty(azureCosmosDbAccountPe)
  ? azureCosmosDbAccountPe
  : '${abbrs.networking.privateEndpoint}${abbrs.databases.cosmosDBDatabase}${resourceToken}'

@description('Name of the Private Endpoint for Azure Key Vault. If left empty, a name will be generated using Azure CAF best practices.')
var _keyVaultPe = !empty(keyVaultPe)
  ? keyVaultPe
  : '${abbrs.networking.privateEndpoint}${abbrs.security.keyVault}${resourceToken}'

@description('Name of the Private Endpoint for Azure App Configuration. If left empty, a name will be generated using Azure CAF best practices.')
var _appConfigPe = !empty(appConfigPe)
  ? appConfigPe
  : '${abbrs.networking.privateEndpoint}${abbrs.developerTools.appConfigurationStore}${resourceToken}'

@description('Name of the Private Link for Azure Monitor. If left empty, a name will be generated using Azure CAF best practices.')
var _azureMonitorPrivateLinkName = !empty(azureMonitorPrivateLinkName)
  ? azureMonitorPrivateLinkName
  : '${abbrs.networking.privateLink}${abbrs.managementGovernance.logAnalyticsWorkspace}${resourceToken}'

@description('Name of the Private Endpoint for Log Analytics Workspace. If left empty, a name will be generated using Azure CAF best practices.')
var _logAnalyticsPe = !empty(logAnalyticsPe)
  ? logAnalyticsPe
  : '${abbrs.networking.privateEndpoint}${abbrs.managementGovernance.logAnalyticsWorkspace}${resourceToken}'

@description('Name of the Private Endpoint for Azure AI Services. If left empty, a name will be generated using Azure CAF best practices.')
var _aiServicesPe = !empty(aiServicesPe)
  ? aiServicesPe
  : '${abbrs.networking.privateEndpoint}${abbrs.ai.aiServices}${resourceToken}'

@description('Name of the Azure Cosmos DB account to store application data. If left empty, a name will be generated using Azure CAF best practices.')
var _azureCosmosDbName = _azureReuseConfig.cosmosDbReuse
  ? _azureReuseConfig.existingCosmosDbAccountName
  : !empty(azureCosmosDbName) ? azureCosmosDbName : '${abbrs.databases.cosmosDBTable}${resourceToken}'

@description('Name of the Azure Cosmos DB database to create in the account. If left empty, a name will be generated using Azure CAF best practices.')
var _azureCosmosDatabaseName = _azureReuseConfig.cosmosDbReuse
  ? _azureReuseConfig.existingCosmosDbDatabaseName
  : !empty(azureCosmosDatabaseName) ? azureCosmosDatabaseName : '${abbrs.databases.cosmosDBDatabase}${resourceToken}'

@description('Name of the Azure AI services instance. If left empty, a name will be generated using Azure CAF best practices.')
var _aiServicesName = _azureReuseConfig.aiServicesReuse
  ? _azureReuseConfig.existingAiServicesName
  : !empty(aiServicesName) ? aiServicesName : '${abbrs.ai.aiServices}${resourceToken}'

@description('API version for the Azure OpenAI Service. Defaults to 2025-03-01-preview.')
var _openaiApiVersion = !empty(openaiApiVersion) ? openaiApiVersion : '2025-03-01-preview'

@description('Name of the Azure Storage account to store application data. If left empty, a name will be generated using Azure CAF best practices.')
var _storageAccountName = _azureReuseConfig.storageReuse
  ? _azureReuseConfig.existingStorageName
  : !empty(storageAccountName) ? storageAccountName : '${abbrs.storage.storageAccount}${resourceToken}'

@description('Name of the Azure Storage blob container to store documents to process. Defaults to documents.')
var _storageContainerName = !empty(storageContainerName) ? storageContainerName : 'documents'

@description('Name of the Azure Key Vault to store application secrets. If left empty, a name will be generated using Azure CAF best practices.')
var _keyVaultName = _azureReuseConfig.keyVaultReuse
  ? _azureReuseConfig.existingKeyVaultName
  : !empty(keyVaultName) ? keyVaultName : '${abbrs.security.keyVault}${resourceToken}'

@description('Name of the App Configuration Store to store application settings. If left empty, a name will be generated using Azure CAF best practices.')
var _appConfigName = _azureReuseConfig.appConfigReuse
  ? _azureReuseConfig.existingAppConfigName
  : !empty(appConfigName) ? appConfigName : '${abbrs.developerTools.appConfigurationStore}${resourceToken}'

@description('Name of the Log Analytics Workspace to store logs and metrics. If left empty, a name will be generated using Azure CAF best practices.')
var _logAnalyticsWorkspaceName = _azureReuseConfig.logAnalyticsWorkspaceReuse
  ? _azureReuseConfig.existingLogAnalyticsWorkspaceName
  : !empty(logAnalyticsWorkspaceName)
      ? logAnalyticsWorkspaceName
      : '${abbrs.managementGovernance.logAnalyticsWorkspace}${resourceToken}'

@description('Name of the Application Insights instance to monitor the application. If left empty, a name will be generated using Azure CAF best practices.')
var _applicationInsightsName = _azureReuseConfig.appInsightsReuse
  ? _azureReuseConfig.existingAppInsightsName
  : !empty(applicationInsightsName)
      ? applicationInsightsName
      : '${abbrs.managementGovernance.applicationInsights}${resourceToken}'

@description('Name of the Private Endpoint for Azure Container Registry. If left empty, a name will be generated using Azure CAF best practices.')
var _containerRegistryPeName = !empty(containerRegistryPe)
  ? containerRegistryPe
  : '${abbrs.networking.privateEndpoint}${abbrs.containers.containerRegistry}${resourceToken}'

@description('Name of the Azure Container Registry to store application images. If left empty, a name will be generated using Azure CAF best practices.')
var _containerRegistryName = _azureReuseConfig.containerRegistryReuse
  ? _azureReuseConfig.existingContainerRegistryName
  : !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containers.containerRegistry}${resourceToken}'

@description('Name of the Azure Container Apps environment. If left empty, a name will be generated using Azure CAF best practices.')
var _containerAppsEnvironmentName = _azureReuseConfig.containerAppsEnvironmentReuse
  ? _azureReuseConfig.existingContainerAppsEnvironmentName
  : !empty(containerAppsEnvironmentName)
      ? containerAppsEnvironmentName
      : '${abbrs.containers.containerAppsEnvironment}${resourceToken}'

@description('Name of the Private Endpoint for Azure Container Apps environment. If left empty, a name will be generated using Azure CAF best practices.')
var _containerAppsEnvironmentPe = !empty(containerAppsEnvironmentPe)
  ? containerAppsEnvironmentPe
  : '${abbrs.networking.privateEndpoint}${abbrs.containers.containerAppsEnvironment}${resourceToken}'

@description('Name of the Private Endpoint for Azure AI Foundry Hub. If left empty, a name will be generated using Azure CAF best practices.')
var _aiHubPe = !empty(aiHubPe) ? aiHubPe : '${abbrs.networking.privateEndpoint}${abbrs.ai.aiHub}${resourceToken}'

@description('Name of the Azure AI Foundry Hub to manage resources for AI projects. If left empty, a name will be generated using Azure CAF best practices.')
var _aiHubName = _azureReuseConfig.aiHubReuse
  ? _azureReuseConfig.existingAiHubName
  : !empty(aiHubName) ? aiHubName : '${abbrs.ai.aiHub}${resourceToken}'

@description('Name of the Azure AI Foundry Hub project to build, test, and deploy AI capabilities. If left empty, a name will be generated using Azure CAF best practices.')
var _aiHubProjectName = _azureReuseConfig.aiHubReuse
  ? _azureReuseConfig.existingAiHubProjectName
  : !empty(aiHubProjectName) ? aiHubProjectName : '${abbrs.ai.aiHubProject}${resourceToken}'

@description('VM Administrator Login assignments for the defined identities.')
var virtualMachineAdministratorLoginIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: virtualMachineAdministratorLoginRole.id
    principalType: identity.principalType
  }
]

@description('App Config Data Owner assignments for the defined identities.')
var appConfigDataOwnerIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: appConfigDataOwnerRole.id
    principalType: identity.principalType
  }
]

@description('All App Config Data Owner assignments for the defined identities and the AI Services managed identity.')
var appConfigDataOwnerAssignments = concat(appConfigDataOwnerIdentityAssignments, [
  {
    principalId: aiServices.outputs.identityPrincipalId
    roleDefinitionId: appConfigDataOwnerRole.id
    principalType: 'ServicePrincipal'
  }
])

@description('Contributor assignments for the defined identities.')
var contributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: contributorRole.id
    principalType: identity.principalType
  }
]

@description('Key Vault Secrets User assignments for the defined identities.')
var keyVaultSecretsUserIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: keyVaultSecretsUserRole.id
    principalType: identity.principalType
  }
]

@description('Cognitive Services User assignments for the defined identities.')
var cognitiveServicesUserRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: cognitiveServicesUserRole.id
    principalType: identity.principalType
  }
]

@description('Cognitive Services OpenAI User assignments for the defined identities.')
var cognitiveServicesOpenAIUserRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: cognitiveServicesOpenAIUserRole.id
    principalType: identity.principalType
  }
]

@description('Storage Account Contributor assignments for the defined identities.')
var storageAccountContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageAccountContributorRole.id
    principalType: identity.principalType
  }
]

@description('Storage Blob Data Contributor assignments for the defined identities.')
var storageBlobDataContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageBlobDataContributorRole.id
    principalType: identity.principalType
  }
]

@description('Storage Blob Data Owner assignments for the defined identities.')
var storageBlobDataOwnerIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageBlobDataOwnerRole.id
    principalType: identity.principalType
  }
]

@description('Storage File Data Privileged Contributor assignments for the defined identities.')
var storageFileDataPrivilegedContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageFileDataPrivilegedContributorRole.id
    principalType: identity.principalType
  }
]

@description('Storage Table Data Contributor assignments for the defined identities.')
var storageTableDataContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageTableDataContributorRole.id
    principalType: identity.principalType
  }
]

@description('Storage Queue Data Contributor assignments for the defined identities.')
var storageQueueDataContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: storageQueueDataContributorRole.id
    principalType: identity.principalType
  }
]

@description('ACR Push assignments for the defined identities.')
var acrPushIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: acrPushRole.id
    principalType: identity.principalType
  }
]

@description('ACR Pull assignments for the defined identities.')
var acrPullIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: acrPullRole.id
    principalType: identity.principalType
  }
]

@description('Azure ML Data Scientist assignments for the defined identities.')
var azureMLDataScientistRoleAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: azureMLDataScientistRole.id
    principalType: identity.principalType
  }
]

@description('Cosmos DB Account Contributor assignments for the defined identities.')
var cosmosDbAccountContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: cosmosDbAccountContributorRole.id
    principalType: identity.principalType
  }
]

@description('Cosmos DB Data Contributor assignments for the defined identities.')
var cosmosDbDataContributorIdentityAssignments = [
  for identity in identities: {
    principalId: identity.principalId
    roleDefinitionId: '00000000-0000-0000-0000-000000000002' // Cosmos DB Built-in Data Contributor role
    principalType: identity.principalType
  }
]

@description('Secure application settings to be stored in the Key Vault.')
var secureAppSettings = [
  {
    name: _vmUserPasswordKeyVaultSecretName
    value: vmUserInitialPassword!
  }
]

@description('Application settings to be stored in the App Configuration Store.')
var appSettings = [
  {
    name: 'AZURE_AISERVICES_ENDPOINT'
    value: aiServices.outputs.endpoint
  }
  {
    name: 'AZURE_OPENAI_ENDPOINT'
    value: aiServices.outputs.openAIEndpoint
  }
  {
    name: 'AZURE_OPENAI_CHAT_DEPLOYMENT'
    value: chatModelDeployment.name
  }
  {
    name: 'AZURE_STORAGE_ACCOUNT'
    value: _storageAccountName
  }
  {
    name: 'NETWORK_ISOLATION'
    value: string(networkIsolation)
  }
  {
    name: 'AZURE_OPENAI_API_VERSION'
    value: _openaiApiVersion
  }
  {
    name: 'AZURE_SUBSCRIPTION_ID'
    value: subscription().subscriptionId
  }
  {
    name: 'AZURE_RESOURCE_GROUP_NAME'
    value: _resourceGroupName
  }
  {
    name: 'LOGLEVEL'
    value: 'INFO'
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: applicationInsights.outputs.connectionString
  }
  {
    name: 'WEBSITE_HTTPLOGGING_RETENTION_DAYS'
    value: '7'
  }
]

// Deployments

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: _resourceGroupName
  location: location
  tags: union(tags, {})
}

resource contributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.general.contributor
}

module resourceGroupRoleAssignment './security/resource-group-role-assignment.bicep' = {
  name: '${_resourceGroupName}-role'
  scope: resourceGroup
  params: {
    roleAssignments: concat(contributorIdentityAssignments, [])
  }
}

module aiNsg './networking/network-security-group.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _aiNsgName
  scope: resourceGroup
  params: {
    name: _aiNsgName
    location: location
    tags: union(tags, {})
    securityRules: []
  }
}

module acaNsg './networking/network-security-group.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _acaNsgName
  scope: resourceGroup
  params: {
    name: _acaNsgName
    location: location
    tags: union(tags, {})
    securityRules: []
  }
}

module bastionNsg './networking/network-security-group.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _bastionNsgName
  scope: resourceGroup
  params: {
    name: _bastionNsgName
    location: location
    tags: union(tags, {})
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          priority: 120
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowLoadBalancerInbound'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshRdpOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudCommunicationOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowGetSessionInformationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRanges: [
            '80'
            '443'
          ]
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
    ]
  }
}

module databaseNsg './networking/network-security-group.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _databaseNsgName
  scope: resourceGroup
  params: {
    name: _databaseNsgName
    location: location
    tags: union(tags, {})
    securityRules: []
  }
}

module vnet './networking/virtual-network.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _vnetName
  scope: resourceGroup
  params: {
    name: _vnetName
    location: location
    tags: union(tags, {})
    addressPrefixes: [_vnetAddress]
    subnets: [
      {
        name: _aiSubnetName
        addressPrefix: _aiSubnetPrefix
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        networkSecurityGroup: {
          id: aiNsg.outputs.id
        }
      }
      {
        name: _acaSubnetName
        addressPrefix: _acaSubnetPrefix
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        networkSecurityGroup: {
          id: acaNsg.outputs.id
        }
        delegations: [
          {
            name: 'Microsoft.App/environments'
            properties: {
              serviceName: 'Microsoft.App/environments'
            }
            type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
          }
        ]
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: _bastionSubnetPrefix
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        networkSecurityGroup: {
          id: bastionNsg.outputs.id
        }
      }
      {
        name: _databaseSubnetName
        addressPrefix: _databaseSubnetPrefix
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
        networkSecurityGroup: {
          id: databaseNsg.outputs.id
        }
      }
    ]
  }
}

module vpnGateway './networking/vnet-vpn-gateway.bicep' = if (networkIsolation && !_vnetReuse && deployVPN) {
  scope: resourceGroup
  name: _vpnGatewayName
  params: {
    name: _vpnGatewayName
    location: location
    tags: union(tags, {})
    vnetName: vnet.outputs.name
    vnetAddressPrefix: _vnetAddress
    vpnGatewayPublicIpName: _vpnGatewayPublicIpName
    vpnGatewaySubnetAddressPrefix: '10.0.1.128/26'
    vpnClientAddressPool: '172.16.0.0/24'
  }
}

resource virtualMachineAdministratorLoginRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.compute.virtualMachineAdministratorLogin
}

module virtualMachine './compute/dsvm.bicep' = if (networkIsolation && !_vnetReuse && deployVM) {
  name: _vmName
  scope: resourceGroup
  params: {
    name: _vmName
    location: location
    tags: union(tags, {})
    subnetId: networkIsolation ? vnet.outputs.subnets[0].id : ''
    bastionSubId: networkIsolation ? vnet.outputs.subnets[2].id : ''
    bastionName: bastionHostName
    bastionPublicIpName: bastionHostPublicIpName
    nicName: vmNicName
    vmOSDiskName: vmOSDiskName
    vmUserName: _vmUserName!
    vmUserPassword: vmUserInitialPassword!
    keyVaultConfig: {
      keyVaultName: _bastionKeyVaultName
      vmUserPasswordSecretName: _vmUserPasswordKeyVaultSecretName
    }
    vmManagedIdentityName: vmManagedIdentityName
    vmRoleAssignments: concat(virtualMachineAdministratorLoginIdentityAssignments, [])
  }
}

module keyVaultDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'vault-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.vaultcore.azure.net'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module storageBlobDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'blob-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.blob.${environment().suffixes.storage}'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module storageQueueDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'queue-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.queue.${environment().suffixes.storage}'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module storageTableDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'table-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.table.${environment().suffixes.storage}'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module storageFileDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'file-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.file.${environment().suffixes.storage}'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module cosmosDbDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'cosmos-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.documents.azure.com'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module appConfigDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'appconfig-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.azconfig.io'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module aiServicesDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'aiservices-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.cognitiveservices.azure.com'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module openAIDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'openai-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.openai.azure.com'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module containerRegistryDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'acr-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.azurecr.io'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module azureMonitorDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'azmonitor-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.monitor.azure.com'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module containerAppsDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'cae-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.${split(containerAppsEnvironment.outputs.defaultDomain, '.')[1]}.azurecontainerapps.io'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module mlApiPrivateDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'mlapi-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.api.azureml.ms'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

module mlNotebooksPrivateDnsZone './networking/private-dns-zones.bicep' = if (networkIsolation && !_vnetReuse) {
  name: 'mlnotebooks-dnszone'
  scope: resourceGroup
  params: {
    name: 'privatelink.notebooks.azureml.net'
    tags: union(tags, {})
    virtualNetworkName: vnet.outputs.name
  }
}

resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.security.keyVaultSecretsUser
}

module keyVault './security/key-vault.bicep' = {
  name: _keyVaultName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.keyVaultReuse,
    _azureReuseConfig.existingKeyVaultResourceGroupName
  ))
  params: {
    name: _keyVaultName
    location: location
    tags: union(tags, {})
    roleAssignments: concat(keyVaultSecretsUserIdentityAssignments, [])
    secureAppSettings: secureAppSettings
    publicNetworkAccess: networkIsolation ? 'Disabled' : 'Enabled'
  }
}

module keyVaultPrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _keyVaultPe
  scope: resourceGroup
  params: {
    name: _keyVaultPe
    location: location
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: keyVault.outputs.id
    groupIds: ['Vault']
    dnsZoneGroups: [
      {
        name: replace(keyVaultDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: keyVaultDnsZone.outputs.id
        }
      }
    ]
  }
}

resource appConfigDataOwnerRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.integration.appConfigurationDataOwner
}

module appConfig './developer_tools/app-configuration-store.bicep' = {
  name: _appConfigName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.appConfigReuse,
    _azureReuseConfig.existingAppConfigResourceGroupName
  ))
  params: {
    name: _appConfigName
    location: location
    tags: union(tags, {})
    appSettings: !deployAppConfigValues ? [] : appSettings
    secureAppSettings: !deployAppConfigValues ? [] : keyVault.outputs.secrets
    roleAssignments: concat(appConfigDataOwnerAssignments, [])
  }
}

module appConfigPrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _appConfigPe
  scope: resourceGroup
  params: {
    name: _appConfigPe
    location: location
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: appConfig.outputs.id
    groupIds: ['configurationStores']
    dnsZoneGroups: [
      {
        name: replace(appConfigDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: appConfigDnsZone.outputs.id
        }
      }
    ]
  }
}

module logAnalyticsWorkspace './management_governance/log-analytics-workspace.bicep' = {
  name: _logAnalyticsWorkspaceName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.logAnalyticsWorkspaceReuse,
    _azureReuseConfig.existingLogAnalyticsWorkspaceResourceGroupName
  ))
  params: {
    name: _logAnalyticsWorkspaceName
    location: location
    tags: union(tags, {})
  }
}

module azureMonitorPrivateLinkScope './management_governance/private-link-scope.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _azureMonitorPrivateLinkName
  scope: resourceGroup
  params: {
    name: _azureMonitorPrivateLinkName
    scopedResourceIds: [
      logAnalyticsWorkspace.outputs.id
    ]
  }
}

module logAnalyticsPrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _logAnalyticsPe
  scope: resourceGroup
  params: {
    name: _logAnalyticsPe
    location: location
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: azureMonitorPrivateLinkScope.outputs.id
    groupIds: ['azuremonitor']
    dnsZoneGroups: [
      {
        name: replace(azureMonitorDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: azureMonitorDnsZone.outputs.id
        }
      }
    ]
  }
}

module applicationInsights './management_governance/application-insights.bicep' = {
  name: _applicationInsightsName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.appInsightsReuse,
    _azureReuseConfig.existingAppInsightsResourceGroupName
  ))
  params: {
    name: _applicationInsightsName
    location: location
    tags: union(tags, {})
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    publicNetworkAccessForIngestion: networkIsolation ? 'Disabled' : 'Enabled'
    publicNetworkAccessForQuery: networkIsolation ? 'Disabled' : 'Enabled'
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

module aiServices './ai_ml/ai-services.bicep' = {
  name: _aiServicesName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.aiServicesReuse,
    _azureReuseConfig.existingAiServicesResourceGroupName
  ))
  params: {
    name: _aiServicesName
    location: location
    tags: union(tags, {})
    raiPolicies: raiPolicies
    deployments: [
      chatModelDeployment
    ]
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    roleAssignments: concat(cognitiveServicesUserRoleAssignments, cognitiveServicesOpenAIUserRoleAssignments, [])
    publicNetworkAccess: networkIsolation ? 'Disabled' : 'Enabled'
  }
}

// Require self-referencing role assignment for AI Services identity to access Azure OpenAI.
module aiServicesRoleAssignment './security/resource-role-assignment.json' = {
  name: '${aiServices.name}-role'
  scope: resourceGroup
  params: {
    resourceId: aiServices.outputs.id
    roleAssignments: [
      {
        principalId: aiServices.outputs.identityPrincipalId
        roleDefinitionId: cognitiveServicesUserRole.id
        principalType: 'ServicePrincipal'
      }
    ]
  }
}

module aiServicesPrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _aiServicesPe
  scope: resourceGroup
  params: {
    name: _aiServicesPe
    location: location
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: aiServices.outputs.id
    groupIds: ['account']
    dnsZoneGroups: [
      {
        name: replace(aiServicesDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: aiServicesDnsZone.outputs.id
        }
      }
      {
        name: replace(openAIDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: openAIDnsZone.outputs.id
        }
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

resource storageBlobDataOwnerRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
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

resource storageQueueDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.storage.storageQueueDataContributor
}

module storageAccount './storage/storage-account.bicep' = {
  name: _storageAccountName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.storageReuse,
    _azureReuseConfig.existingStorageResourceGroupName
  ))
  params: {
    name: _storageAccountName
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Standard_LRS'
    }
    publicNetworkAccess: networkIsolation ? 'Disabled' : 'Enabled'
    roleAssignments: concat(
      storageAccountContributorIdentityAssignments,
      storageBlobDataContributorIdentityAssignments,
      storageBlobDataOwnerIdentityAssignments,
      storageFileDataPrivilegedContributorIdentityAssignments,
      storageTableDataContributorIdentityAssignments,
      storageQueueDataContributorIdentityAssignments,
      [
        {
          principalId: aiServices.outputs.identityPrincipalId
          roleDefinitionId: storageBlobDataContributorRole.id
          principalType: 'ServicePrincipal'
        }
      ]
    )
  }
}

module storageContainer 'storage/storage-blob-container.bicep' = {
  name: '${storageAccount.name}-container-${_storageContainerName}'
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.storageReuse,
    _azureReuseConfig.existingStorageResourceGroupName
  ))
  params: {
    name: _storageContainerName
    storageAccountName: storageAccount.outputs.name
  }
}

module storageBlobPrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _azureBlobStorageAccountPe
  scope: resourceGroup
  params: {
    name: _azureBlobStorageAccountPe
    location: location
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: storageAccount.outputs.id
    groupIds: ['blob']
    dnsZoneGroups: [
      {
        name: replace(storageBlobDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: storageBlobDnsZone.outputs.id
        }
      }
    ]
  }
}

module storageTablePrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _azureTableStorageAccountPe
  scope: resourceGroup
  params: {
    name: _azureTableStorageAccountPe
    location: location
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: storageAccount.outputs.id
    groupIds: ['table']
    dnsZoneGroups: [
      {
        name: replace(storageTableDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: storageTableDnsZone.outputs.id
        }
      }
    ]
  }
}

module storageQueuePrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _azureQueueStorageAccountPe
  scope: resourceGroup
  params: {
    name: _azureQueueStorageAccountPe
    location: location
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: storageAccount.outputs.id
    groupIds: ['queue']
    dnsZoneGroups: [
      {
        name: replace(storageQueueDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: storageQueueDnsZone.outputs.id
        }
      }
    ]
  }
}

module storageFilePrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _azureFileStorageAccountPe
  scope: resourceGroup
  params: {
    name: _azureFileStorageAccountPe
    location: location
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: storageAccount.outputs.id
    groupIds: ['file']
    dnsZoneGroups: [
      {
        name: replace(storageFileDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: storageFileDnsZone.outputs.id
        }
      }
    ]
  }
}

resource cosmosDbAccountContributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.databases.documentDBAccountContributor
}

module cosmosDbAccount './databases/cosmos-db-account.bicep' = {
  name: _azureCosmosDbName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.cosmosDbReuse,
    _azureReuseConfig.existingCosmosDbResourceGroupName
  ))
  params: {
    name: _azureCosmosDbName
    location: location
    tags: union(tags, {})
    georeplicationLocations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    roleAssignments: concat(cosmosDbAccountContributorIdentityAssignments, [])
    dataRoleAssignments: concat(cosmosDbDataContributorIdentityAssignments, [])
  }
}

module cosmosDbDatabase './databases/cosmos-db-database.bicep' = {
  name: _azureCosmosDatabaseName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.cosmosDbReuse,
    _azureReuseConfig.existingCosmosDbResourceGroupName
  ))
  params: {
    name: _azureCosmosDatabaseName
    tags: union(tags, {})
    cosmosDbName: cosmosDbAccount.outputs.name
    containers: []
  }
}

module cosmosDbPrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _azureCosmosDbAccountPe
  scope: resourceGroup
  params: {
    name: _azureCosmosDbAccountPe
    location: location
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[3].id
    serviceId: cosmosDbAccount.outputs.id
    groupIds: ['Sql']
    dnsZoneGroups: [
      {
        name: replace(cosmosDbDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: cosmosDbDnsZone.outputs.id
        }
      }
    ]
  }
}

resource acrPushRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.containers.acrPush
}

resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.containers.acrPull
}

module containerRegistry 'containers/container-registry.bicep' = {
  name: _containerRegistryName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.containerRegistryReuse,
    _azureReuseConfig.existingContainerRegistryResourceGroupName
  ))
  params: {
    name: _containerRegistryName
    location: location
    tags: union(tags, {})
    sku: {
      name: 'Premium'
    }
    adminUserEnabled: false
    roleAssignments: concat(acrPushIdentityAssignments, acrPullIdentityAssignments, [])
    publicNetworkAccess: 'Disabled'
  }
}

module containerRegistryPrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _containerRegistryPeName
  scope: resourceGroup
  params: {
    location: location
    name: _containerRegistryPeName
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: containerRegistry.outputs.id
    groupIds: ['registry']
    dnsZoneGroups: [
      {
        name: replace(containerRegistryDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: containerRegistryDnsZone.outputs.id
        }
      }
    ]
  }
}

module containerAppsEnvironment 'containers/container-apps-environment.bicep' = {
  name: _containerAppsEnvironmentName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.containerAppsEnvironmentReuse,
    _azureReuseConfig.existingContainerAppsEnvironmentResourceGroupName
  ))
  params: {
    name: _containerAppsEnvironmentName
    location: location
    tags: union(tags, {})
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
    applicationInsightsName: applicationInsights.outputs.name
    vnetConfig: {
      infrastructureSubnetId: networkIsolation ? vnet.outputs.subnets[1].id : ''
      internal: true
    }
  }
}

module containerAppsEnvironmentPrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _containerAppsEnvironmentPe
  scope: resourceGroup
  params: {
    name: _containerAppsEnvironmentPe
    location: location
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: containerAppsEnvironment.outputs.id
    groupIds: ['managedEnvironments']
    dnsZoneGroups: [
      {
        name: replace(containerAppsDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: containerAppsDnsZone.outputs.id
        }
      }
    ]
  }
}

resource azureMLDataScientistRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup
  name: roles.ai.azureMLDataScientist
}

module aiHub './ai_ml/ai-hub.bicep' = {
  name: _aiHubName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.aiHubReuse,
    _azureReuseConfig.existingAiHubResourceGroupName
  ))
  params: {
    name: _aiHubName
    friendlyName: 'Hub - AI Document Pipeline'
    descriptionInfo: 'Generated by the AI Document Pipeline Accelerator'
    location: location
    tags: union(tags, {})
    storageAccountId: storageAccount.outputs.id
    keyVaultId: keyVault.outputs.id
    applicationInsightsId: applicationInsights.outputs.id
    containerRegistryId: containerRegistry.outputs.id
    aiServicesName: aiServices.outputs.name
    roleAssignments: concat(azureMLDataScientistRoleAssignments, [])
    publicNetworkAccess: networkIsolation ? 'Disabled' : 'Enabled'
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
}

module aiHubPrivateEndpoint './networking/private-endpoint.bicep' = if (networkIsolation && !_vnetReuse) {
  name: _aiHubPe
  scope: resourceGroup
  params: {
    location: location
    name: _aiHubPe
    tags: union(tags, {})
    subnetId: vnet.outputs.subnets[0].id
    serviceId: aiHub.outputs.id
    groupIds: ['amlworkspace']
    dnsZoneGroups: [
      {
        name: replace(mlApiPrivateDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: mlApiPrivateDnsZone.outputs.id
        }
      }
      {
        name: replace(mlNotebooksPrivateDnsZone.outputs.name, '.', '-')
        properties: {
          privateDnsZoneId: mlNotebooksPrivateDnsZone.outputs.id
        }
      }
    ]
  }
}

module aiHubProject './ai_ml/ai-hub-project.bicep' = {
  name: _aiHubProjectName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.aiHubReuse,
    _azureReuseConfig.existingAiHubResourceGroupName
  ))
  params: {
    name: _aiHubProjectName
    friendlyName: 'Project - AI Document Pipeline'
    descriptionInfo: 'Generated by the AI Document Pipeline Accelerator'
    location: location
    tags: union(tags, {})
    aiHubName: aiHub.outputs.name
    roleAssignments: concat(azureMLDataScientistRoleAssignments, [])
    publicNetworkAccess: networkIsolation ? 'Disabled' : 'Enabled'
    logAnalyticsWorkspaceName: logAnalyticsWorkspace.outputs.name
  }
}

module documentPipelineApp './apps/AIDocumentPipeline/app.bicep' = {
  name: applicationName
  scope: az.resourceGroup(resourceGroupScope(
    _resourceGroupName,
    _azureReuseConfig.containerAppsEnvironmentReuse,
    _azureReuseConfig.existingContainerAppsEnvironmentResourceGroupName
  ))
  params: {
    workloadName: workloadName
    location: location
    tags: union(tags, {
      ApplicationName: applicationName
    })
    applicationName: applicationName
    containerImageName: 'mcr.microsoft.com/k8se/quickstart:latest'
    chatModelDeployment: chatModelDeployment.name
    appConfigName: appConfig.outputs.name
    containerRegistryName: containerRegistry.outputs.name
    applicationInsightsName: applicationInsights.outputs.name
    storageAccountName: storageAccount.outputs.name
    aiServicesName: aiServices.outputs.name
    containerAppsEnvironmentName: containerAppsEnvironment.outputs.name
  }
}

// Outputs

output environmentInfo object = {
  workloadName: workloadName
  azureResourceGroup: resourceGroup.name
  azureLocation: resourceGroup.location
  containerRegistryName: containerRegistry.outputs.name
  azureAIServicesEndpoint: aiServices.outputs.endpoint
  azureOpenAIEndpoint: aiServices.outputs.openAIEndpoint
  azureOpenAIChatDeployment: chatModelDeployment.name
  azureStorageAccount: storageAccount.outputs.name
  azureApplicationInsightsName: applicationInsights.outputs.name
  appConfigurationName: appConfig.outputs.name
  azureAIServicesName: aiServices.outputs.name
  azureContainerAppsEnvironment: containerAppsEnvironment.outputs.name
  applicationName: applicationName
  applicationContainerAppName: documentPipelineApp.outputs.appInfo.name
  applicationContainerAppUrl: documentPipelineApp.outputs.appInfo.url
}
