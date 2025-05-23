using './core.bicep'
extends './root.bicepparam'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', '')

param workloadName = 'ai-document-pipeline'

param location = readEnvironmentVariable('AZURE_LOCATION', 'eastus')

param tags = {
  'azd-env-name': environmentName
  WorkloadName: workloadName
  Environment: 'Dev'
}

param applicationName = 'ai-document-pipeline'

param azureReuseConfig = {
  containerRegistryReuse: readEnvironmentVariable('CONTAINER_REGISTRY_REUSE', '')
  existingContainerRegistryResourceGroupName: readEnvironmentVariable('CONTAINER_REGISTRY_RESOURCE_GROUP_NAME', '')
  existingContainerRegistryName: readEnvironmentVariable('CONTAINER_REGISTRY_NAME', '')
  logAnalyticsWorkspaceReuse: readEnvironmentVariable('LOG_ANALYTICS_WORKSPACE_REUSE', '')
  existingLogAnalyticsWorkspaceResourceGroupName: readEnvironmentVariable(
    'LOG_ANALYTICS_WORKSPACE_RESOURCE_GROUP_NAME',
    ''
  )
  existingLogAnalyticsWorkspaceName: readEnvironmentVariable('LOG_ANALYTICS_WORKSPACE_NAME', '')
  appInsightsReuse: readEnvironmentVariable('APP_INSIGHTS_REUSE', '')
  existingAppInsightsResourceGroupName: readEnvironmentVariable('APP_INSIGHTS_RESOURCE_GROUP_NAME', '')
  existingAppInsightsName: readEnvironmentVariable('APP_INSIGHTS_NAME', '')
  aiServicesReuse: readEnvironmentVariable('AZURE_AI_SERVICES_REUSE', '')
  existingAiServicesResourceGroupName: readEnvironmentVariable('AZURE_AI_SERVICES_RESOURCE_GROUP_NAME', '')
  existingAiServicesName: readEnvironmentVariable('AZURE_AI_SERVICES_NAME', '')
  cosmosDbReuse: readEnvironmentVariable('AZURE_DB_REUSE', '')
  existingCosmosDbResourceGroupName: readEnvironmentVariable('AZURE_DB_RESOURCE_GROUP_NAME', '')
  existingCosmosDbAccountName: readEnvironmentVariable('AZURE_DB_ACCOUNT_NAME', '')
  existingCosmosDbDatabaseName: readEnvironmentVariable('AZURE_DB_DATABASE_NAME', '')
  keyVaultReuse: readEnvironmentVariable('AZURE_KEY_VAULT_REUSE', '')
  existingKeyVaultResourceGroupName: readEnvironmentVariable('AZURE_KEY_VAULT_RESOURCE_GROUP_NAME', '')
  existingKeyVaultName: readEnvironmentVariable('AZURE_KEY_VAULT_NAME', '')
  storageReuse: readEnvironmentVariable('AZURE_STORAGE_ACCOUNT_REUSE', '')
  existingStorageResourceGroupName: readEnvironmentVariable('AZURE_STORAGE_ACCOUNT_RESOURCE_GROUP_NAME', '')
  existingStorageName: readEnvironmentVariable('AZURE_STORAGE_ACCOUNT_NAME', '')
  vnetReuse: readEnvironmentVariable('AZURE_VNET_REUSE', '')
  existingVnetResourceGroupName: readEnvironmentVariable('AZURE_VNET_RESOURCE_GROUP_NAME', '')
  existingVnetName: readEnvironmentVariable('AZURE_VNET_NAME', '')
  appConfigReuse: readEnvironmentVariable('APP_CONFIG_REUSE', '')
  existingAppConfigResourceGroupName: readEnvironmentVariable('APP_CONFIG_RESOURCE_GROUP_NAME', '')
  existingAppConfigName: readEnvironmentVariable('APP_CONFIG_NAME', '')
  containerAppsEnvironmentReuse: readEnvironmentVariable('CONTAINER_APPS_ENVIRONMENT_REUSE', '')
  existingContainerAppsEnvironmentResourceGroupName: readEnvironmentVariable(
    'CONTAINER_APPS_ENVIRONMENT_RESOURCE_GROUP_NAME',
    ''
  )
  existingContainerAppsEnvironmentName: readEnvironmentVariable('CONTAINER_APPS_ENVIRONMENT_NAME', '')
  aiHubReuse: readEnvironmentVariable('AI_HUB_REUSE', '')
  existingAiHubResourceGroupName: readEnvironmentVariable('AI_HUB_RESOURCE_GROUP_NAME', '')
  existingAiHubName: readEnvironmentVariable('AI_HUB_NAME', '')
  existingAiHubProjectName: readEnvironmentVariable('AI_HUB_PROJECT_NAME', '')
}

param resourceGroupName = readEnvironmentVariable('AZURE_RESOURCE_GROUP_NAME', '')

param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')

param identities = [
  {
    principalId: principalId
    principalType: 'User'
  }
]

param networkIsolation = bool(readEnvironmentVariable('AZURE_NETWORK_ISOLATION', 'false'))

param deployVPN = bool(readEnvironmentVariable('AZURE_VPN_DEPLOY_VPN', 'false'))

param vpnGatewayName = readEnvironmentVariable('AZURE_VPN_GATEWAY_NAME', '')

param vpnGatewayPublicIpName = readEnvironmentVariable('AZURE_VPN_GATEWAY_PUBLIC_IP_NAME', '')

param deployVM = bool(readEnvironmentVariable('AZURE_VM_DEPLOY_VM', 'true'))

param vmName = readEnvironmentVariable('AZURE_VM_NAME', '')

param vmUserName = readEnvironmentVariable('AZURE_VM_USER_NAME', '')

param vmUserInitialPassword = '${uniqueString(principalId, workloadName, 'password')}@123'

param vmUserPasswordKeyVaultSecretName = readEnvironmentVariable('AZURE_VM_KV_SEC_NAME', 'vmUserInitialPassword')

param vnetAddress = readEnvironmentVariable('AZURE_VNET_ADDRESS', '10.0.0.0/23')

param aiNsgName = readEnvironmentVariable('AZURE_AI_NSG_NAME', '')

param aiSubnetName = readEnvironmentVariable('AZURE_AI_SUBNET_NAME', '')

param aiSubnetPrefix = readEnvironmentVariable('AZURE_AI_SUBNET_PREFIX', '10.0.0.0/26')

param acaNsgName = readEnvironmentVariable('AZURE_ACA_NSG_NAME', '')

param acaSubnetName = readEnvironmentVariable('AZURE_ACA_SUBNET_NAME', '')

param acaSubnetPrefix = readEnvironmentVariable('AZURE_ACA_SUBNET_PREFIX', '10.0.1.64/26')

param bastionNsgName = readEnvironmentVariable('AZURE_BASTION_NSG_NAME', '')

param bastionKeyVaultName = readEnvironmentVariable('AZURE_BASTION_KV_NAME', '')

param bastionSubnetPrefix = readEnvironmentVariable('AZURE_BASTION_SUBNET_PREFIX', '10.0.0.64/26')

param databaseNsgName = readEnvironmentVariable('AZURE_DATABASE_NSG_NAME', '')

param databaseSubnetName = readEnvironmentVariable('AZURE_DATABASE_SUBNET_NAME', '')

param databaseSubnetPrefix = readEnvironmentVariable('AZURE_DATABASE_SUBNET_PREFIX', '10.0.1.0/26')

param azureBlobStorageAccountPe = readEnvironmentVariable('AZURE_BLOB_STORAGE_ACCOUNT_PE', '')

param azureTableStorageAccountPe = readEnvironmentVariable('AZURE_TABLE_STORAGE_ACCOUNT_PE', '')

param azureQueueStorageAccountPe = readEnvironmentVariable('AZURE_QUEUE_STORAGE_ACCOUNT_PE', '')

param azureFileStorageAccountPe = readEnvironmentVariable('AZURE_FILE_STORAGE_ACCOUNT_PE', '')

param azureCosmosDbAccountPe = readEnvironmentVariable('AZURE_COSMOS_DB_ACCOUNT_PE', '')

param keyVaultPe = readEnvironmentVariable('AZURE_KEY_VAULT_PE', '')

param appConfigPe = readEnvironmentVariable('AZURE_APP_CONFIG_PE', '')

param azureMonitorPrivateLinkName = readEnvironmentVariable('AZURE_MONITOR_PRIVATE_LINK_NAME', '')

param logAnalyticsPe = readEnvironmentVariable('AZURE_LOG_ANALYTICS_PE', '')

param aiServicesPe = readEnvironmentVariable('AZURE_AI_SERVICES_PE', '')

param containerRegistryPe = readEnvironmentVariable('AZURE_CONTAINER_REGISTRY_PE', '')

param containerAppsEnvironmentPe = readEnvironmentVariable('AZURE_CONTAINER_APPS_ENVIRONMENT_PE', '')

param aiHubPe = readEnvironmentVariable('AZURE_AI_HUB_PE', '')

param deployAppConfigValues = bool(readEnvironmentVariable('AZURE_DEPLOY_APP_CONFIG_VALUES', 'true'))

param chatModelDeploymentModel = 'gpt-4o'

param chatModelDeployment = {
  name: chatModelDeploymentModel
  model: {
    format: 'OpenAI'
    name: 'gpt-4o'
    version: '2024-11-20'
  }
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
  raiPolicyName: workloadName
  versionUpgradeOption: 'OnceCurrentVersionExpired'
}

param raiPolicies = [
  {
    name: workloadName
    mode: 'Blocking'
    prompt: {}
    completion: {}
  }
]

param openaiApiVersion = readEnvironmentVariable('AZURE_OPENAI_API_VERSION', '')

param storageContainerName = readEnvironmentVariable('AZURE_STORAGE_CONTAINER_NAME', '')
