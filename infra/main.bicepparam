using './main.bicep'

extends './root.bicepparam'

param workloadName = 'ai-document-pipeline-cjg'

param raiPolicies = [
  {
    name: workloadName
    mode: 'Blocking'
    prompt: {}
    completion: {}
  }
]

param chatModelDeployment = {
  name: 'gpt-4o'
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

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME','')
param location = readEnvironmentVariable('AZURE_LOCATION','eastus2')
param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID','')

param identities = [{
  principalId: principalId
  principalType: 'User'
}]

param resourceGroupName = workloadName
param networkIsolation = bool(readEnvironmentVariable('AZURE_NETWORK_ISOLATION','false'))
//param provisionLoadTesting = readEnvironmentVariable('AZURE_PROVISION_LOAD_TESTING','')
param vnetName = readEnvironmentVariable('AZURE_VNET_NAME','')
param vnetAddress = readEnvironmentVariable('AZURE_VNET_ADDRESS','')
param chatGptDeploymentName = readEnvironmentVariable('AZURE_CHAT_GPT_DEPLOYMENT_NAME','')
param aiSubnetName = readEnvironmentVariable('AZURE_AI_SUBNET_NAME','')
param aiSubnetPrefix =  readEnvironmentVariable('AZURE_AI_SUBNET_PREFIX','')
param bastionSubnetPrefix =  readEnvironmentVariable('AZURE_BASTION_SUBNET_PREFIX','')
param appIntSubnetName =  readEnvironmentVariable('AZURE_APP_INT_SUBNET_NAME','')
param appIntSubnetPrefix =  readEnvironmentVariable('AZURE_APP_INT_SUBNET_PREFIX','')
param appServicesSubnetName =  readEnvironmentVariable('AZURE_APP_SERVICES_SUBNET_NAME','')
param appServicesSubnetPrefix =  readEnvironmentVariable('AZURE_APP_SERVICES_SUBNET_PREFIX','')
param databaseSubnetName =  readEnvironmentVariable('AZURE_DATABASE_SUBNET_NAME','')
param databaseSubnetPrefix =  readEnvironmentVariable('AZURE_DATABASE_SUBNET_PREFIX','')

param vmKeyVaultSecName = readEnvironmentVariable('AZURE_VM_KV_SEC_NAME','')
param ztVmName = readEnvironmentVariable('AZURE_VM_NAME','')
param deployVM = bool(readEnvironmentVariable('AZURE_VM_DEPLOY_VM','true'))
param vmUserInitialPassword = 'Seattle@123' //az.getSecret(readEnvironmentVariable('AZURE_SUBSCRIPTION_ID',''), resourceGroupName, readEnvironmentVariable('AZURE_BASTION_KV_NAME',''), 'vmUserInitialPassword')
param vmUserName = readEnvironmentVariable('AZURE_VM_USER_NAME','')
param keyVaultName = readEnvironmentVariable('AZURE_KEY_VAULT_NAME','')

param chatGptDeploymentCapacity = int(readEnvironmentVariable('AZURE_CHAT_GPT_DEPLOYMENT_CAPACITY','40'))
param chatGptModelDeploymentType = readEnvironmentVariable('AZURE_CHAT_GPT_DEPLOYMENT_TYPE','')
param chatGptModelName = readEnvironmentVariable('AZURE_CHAT_GPT_MODEL_NAME','')
param chatGptModelVersion = readEnvironmentVariable('AZURE_CHAT_GPT_MODEL_VERSION','')

param embeddingsModelName = readEnvironmentVariable('AZURE_EMBEDDINGS_MODEL_NAME','')
param embeddingsModelVersion = readEnvironmentVariable('AZURE_EMBEDDINGS_VERSION','')
param embeddingsDeploymentName = readEnvironmentVariable('AZURE_EMBEDDINGS_DEPLOYMENT_NAME','')
param embeddingsVectorSize = int(readEnvironmentVariable('AZURE_EMBEDDINGS_VECTOR_SIZE', '1536'))
param openaiApiVersion = readEnvironmentVariable('AZURE_OPENAI_API_VERSION','')

param provisionApplicationInsights = bool(readEnvironmentVariable('AZURE_PROVISION_APPLICATION_INSIGHTS','true'))

param storageAccountName = readEnvironmentVariable('AZURE_STORAGE_ACCOUNT_NAME','')
param storageContainerName = readEnvironmentVariable('AZURE_STORAGE_CONTAINER_NAME','')

param aiServicesName = readEnvironmentVariable('AZURE_AI_SERVICES_NAME','')
param openAiServiceName = readEnvironmentVariable('AZURE_OPENAI_SERVICE_NAME','')

param azureReuseConfig = {
    aoaiReuse: readEnvironmentVariable('AOAI_REUSE', 'false')
    existingAoaiResourceGroupName : readEnvironmentVariable('AOAI_RESOURCE_GROUP_NAME','')
    existingAoaiName : readEnvironmentVariable('AOAI_NAME','')
    appInsightsReuse : readEnvironmentVariable('APP_INSIGHTS_REUSE','')
    existingAppInsightsResourceGroupName : readEnvironmentVariable('APP_INSIGHTS_RESOURCE_GROUP_NAME','')
    existingAppInsightsName : readEnvironmentVariable('APP_INSIGHTS_NAME','')
    logAnalyticsWorkspaceReuse : readEnvironmentVariable('LOG_ANALYTICS_WORKSPACE_REUSE','')
    existingLogAnalyticsWorkspaceResourceId : readEnvironmentVariable('LOG_ANALYTICS_WORKSPACE_ID','')
    appServicePlanReuse : readEnvironmentVariable('APP_SERVICE_PLAN_REUSE','')
    existingAppServicePlanResourceGroupName : readEnvironmentVariable('APP_SERVICE_PLAN_RESOURCE_GROUP_NAME','')
    existingAppServicePlanName : readEnvironmentVariable('APP_SERVICE_PLAN_NAME','')
    aiSearchReuse : readEnvironmentVariable('AI_SEARCH_REUSE','')
    existingAiSearchResourceGroupName : readEnvironmentVariable('AI_SEARCH_RESOURCE_GROUP_NAME','')
    existingAiSearchName : readEnvironmentVariable('AI_SEARCH_NAME','')
    orchestratorFunctionAppReuse : readEnvironmentVariable('ORCHESTRATOR_FUNCTION_APP_REUSE','')
    existingOrchestratorFunctionAppResourceGroupName : readEnvironmentVariable('ORCHESTRATOR_FUNCTION_APP_RESOURCE_GROUP_NAME','')
    existingOrchestratorFunctionAppName : readEnvironmentVariable('ORCHESTRATOR_FUNCTION_APP_NAME','')
    dataIngestionFunctionAppReuse : readEnvironmentVariable('DATA_INGESTION_FUNCTION_APP_REUSE','')
    existingDataIngestionFunctionAppResourceGroupName : readEnvironmentVariable('DATA_INGESTION_FUNCTION_APP_RESOURCE_GROUP_NAME','')
    existingDataIngestionFunctionAppName : readEnvironmentVariable('DATA_INGESTION_FUNCTION_APP_NAME','')
    appServiceReuse : readEnvironmentVariable('APP_SERVICE_REUSE','')
    existingAppServiceName : readEnvironmentVariable('APP_SERVICE_NAME','')
    existingAppServiceNameResourceGroupName : readEnvironmentVariable('APP_SERVICE_RESOURCE_GROUP_NAME','')
    orchestratorFunctionAppStorageReuse : readEnvironmentVariable('ORCHESTRATOR_FUNCTION_APP_STORAGE_REUSE','')
    existingOrchestratorFunctionAppStorageName : readEnvironmentVariable('ORCHESTRATOR_FUNCTION_APP_STORAGE_NAME','')
    existingOrchestratorFunctionAppStorageResourceGroupName : readEnvironmentVariable('ORCHESTRATOR_FUNCTION_APP_STORAGE_RESOURCE_GROUP_NAME','')
    dataIngestionFunctionAppStorageReuse : readEnvironmentVariable('DATA_INGESTION_FUNCTION_APP_STORAGE_REUSE','')
    existingDataIngestionFunctionAppStorageName : readEnvironmentVariable('DATA_INGESTION_FUNCTION_APP_STORAGE_NAME','')
    existingDataIngestionFunctionAppStorageResourceGroupName : readEnvironmentVariable('DATA_INGESTION_FUNCTION_APP_STORAGE_RESOURCE_GROUP_NAME','')
    aiServicesReuse : readEnvironmentVariable('AI_SERVICES_REUSE','')
    existingAiServicesResourceGroupName : readEnvironmentVariable('AI_SERVICES_RESOURCE_GROUP_NAME','')
    existingAiServicesName : readEnvironmentVariable('AI_SERVICES_NAME','')
    cosmosDbReuse : readEnvironmentVariable('COSMOS_DB_REUSE','')
    existingCosmosDbResourceGroupName : readEnvironmentVariable('COSMOS_DB_RESOURCE_GROUP_NAME','')
    existingCosmosDbAccountName : readEnvironmentVariable('COSMOS_DB_ACCOUNT_NAME','')
    existingCosmosDbDatabaseName : readEnvironmentVariable('COSMOS_DB_DATABASE_NAME','')
    keyVaultReuse : readEnvironmentVariable('KEY_VAULT_REUSE','')
    existingKeyVaultResourceGroupName : readEnvironmentVariable('KEY_VAULT_RESOURCE_GROUP_NAME','')
    existingKeyVaultName : readEnvironmentVariable('KEY_VAULT_NAME','')
    storageReuse : readEnvironmentVariable('STORAGE_REUSE','')
    existingStorageResourceGroupName : readEnvironmentVariable('STORAGE_RESOURCE_GROUP_NAME','')
    existingStorageName : readEnvironmentVariable('STORAGE_NAME','')
    vnetReuse : readEnvironmentVariable('VNET_REUSE','')
    existingVnetResourceGroupName : readEnvironmentVariable('VNET_RESOURCE_GROUP_NAME','')
    existingVnetName : readEnvironmentVariable('VNET_NAME','')
  }

param tags = {}
