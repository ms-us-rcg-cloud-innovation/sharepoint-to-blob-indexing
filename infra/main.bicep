targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@description('Resource group name, defaults to rg-env')
param resourceGroupName string = 'rg-${environmentName}'

@minLength(1)
@description('Primary location for all resources')
param location string

@minLength(1)
@description('Tenant Id for MS Graph app registration')
param sharepointGraphTenantId string

@minLength(1)
@description('Client Id for MS Graph app registration')
param sharepointGraphClientId string

@secure()
@minLength(1)
@description('Client Secret for MS Graph app registration')
param sharepointGraphClientSecret string

@minLength(1)
@description('Sharepoint site id')
param sharepointSiteId string

@minLength(1)
@description('Sharepoint site url')
param sharepointSiteUrl string

@minLength(1)
@description('Sharepoint list name')
param sharepointListName string

@minLength(1)
param sharepointUserName string

@secure()
@minLength(1)
param sharepointPassword string


var tags = {
  'azd-env-name': environmentName
}

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module managedIdentity 'modules/managedidentity.bicep' = {
  name: 'managed-identity-${environmentName}-deployment'
  scope: rg
  params: {
    location: location
    managedIdentityName: 'id-${resourceToken}'
    tags: tags
  }
}

module logging 'modules/logging.bicep' = {
  name: 'logging-${environmentName}-deployment'
  scope: rg
  params: {
    appInsightsName: 'appi-${resourceToken}'
    logAnalyticsWorkspaceName: 'law-${resourceToken}'
    location: location
    tags: tags
  }
}

module keyVault 'modules/keyvault.bicep' = {
  name: 'key-vault-${environmentName}-deployment'
  scope: rg
  dependsOn: [
    managedIdentity
  ]
  params: {
    keyVaultName: 'kv${resourceToken}'
    tenantId: subscription().tenantId
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
    managedIdentityName: managedIdentity.outputs.managedIdentityName
  }
}

module storageAccount 'modules/storage.bicep' = {
  name: 'storage-account-${environmentName}-deployment'
  scope: rg
  dependsOn: [
    keyVault
  ]
  params: {
    name: 'sa${resourceToken}'
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

module openAI 'modules/openai.bicep' = {
  name: 'openai-${environmentName}-deployment'
  scope: rg
  dependsOn: [
    keyVault
  ]
  params: {
    name: 'ai-${resourceToken}'
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
    keyVaultName: keyVault.outputs.keyVaultName
  }
}

module aiModelEmbedDeployment  'modules/openaideployment.bicep' = {
  name: 'ai-model-embed-${environmentName}-deployment'
  scope: rg
  dependsOn:[
    openAI
  ]
  params: {
    openAiName: openAI.outputs.name
    deploymentName: 'ai-model-embed-${resourceToken}'
    modelName: 'text-embedding-ada-002'
    modelVersion: '2'
  }
}

module search 'modules/aisearch.bicep' = {
  name: 'ai-search-${environmentName}-deployment'
  scope: rg
  params: {
    name: 'ai-search-${resourceToken}'
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
  }
}

resource kv 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVault.outputs.keyVaultName
  scope: rg
}

module searchIndex 'modules/aisearchindex.bicep' = {
  name: 'ai-search-index-${environmentName}-deployment'
  scope: rg
  dependsOn:[
    search
    openAI
    aiModelEmbedDeployment
    storageAccount
    keyVault
  ]
  params: {
    searchServiceName: search.outputs.name
    location: location
    tags: tags
    searchIndexName: 'idx-sp-${sharepointSiteId}'
    searchIndexerName: 'idxr-sp-${sharepointSiteId}'
    dataSourceName: 'ds-sp-blob-${sharepointSiteId}'
    skillsetName: 'split'
    managedIdentityResourceId: managedIdentity.outputs.id
    storageAccountResourceId: storageAccount.outputs.id
    storageContainerName: storageAccount.outputs.blobContainerName
    storageConnString: kv.getSecret(storageAccount.outputs.connStringSecretName)
    openAIEndpoint: openAI.outputs.endpoint
    openAIEmbeddingsDeployment: aiModelEmbedDeployment.outputs.deploymentName
    openAIEmbeddingsModel: aiModelEmbedDeployment.outputs.modelName
    openAIKey: kv.getSecret(openAI.outputs.keySecretName)
  }
}

module sharepointConnection 'modules/sharepointconnection.bicep' = {
  name: 'sharepoint-conn-${environmentName}-deployment'
  scope: rg
  dependsOn:[
    keyVault
    managedIdentity
  ]
  params: {
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    username: sharepointUserName
    password: sharepointPassword
  }
}


module logicApp 'modules/logicapp.bicep' = {
  name: 'logic-app-${environmentName}-deployment'
  scope: rg
  dependsOn: [
    managedIdentity
    storageAccount
  ]
  params: {
    name: 'logic-${resourceToken}'
    appServicePlanName: 'asp-logic-${resourceToken}'
    appInsightsName: logging.outputs.appInsightsName
    keyVaultName: keyVault.outputs.keyVaultName
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    storageAccountName: storageAccount.outputs.storageAccountName
    storageAccountContainerName: storageAccount.outputs.blobContainerName
    fileShareName: storageAccount.outputs.fileShareName
    storageAcctConnStringName: storageAccount.outputs.connStringSecretName
    sharepointSiteUrl: sharepointSiteUrl
    sharepointListName: sharepointListName
    sharepointSiteId: sharepointSiteId
    sharepointConnectionName: sharepointConnection.outputs.name
  }
}

module functionApp 'modules/functionapp.bicep' = {
  name: 'function-app-${environmentName}-deployment'
  scope: rg
  dependsOn: [
    managedIdentity
    storageAccount
  ]
  params: {
    name: 'func-${resourceToken}'
    appServicePlanName: 'asp-func-${resourceToken}'
    appInsightsName: logging.outputs.appInsightsName
    keyVaultName: keyVault.outputs.keyVaultName
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    storageAcctConnStringName: storageAccount.outputs.connStringSecretName
    fileShareName: storageAccount.outputs.fileShareName
    tenantId: sharepointGraphTenantId 
    clientId: sharepointGraphClientId
    clientSecret: sharepointGraphClientSecret
    storageAcctContainerName: storageAccount.outputs.blobContainerName
    sharepointSiteId: sharepointSiteId
  }
}

output AZURE_RESOURCE_GROUP_NAME string = rg.name
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = subscription().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_LOGIC_APP_NAME string = logicApp.outputs.logicAppName
output AZURE_FUNCTION_APP_NAME string = functionApp.outputs.functionAppName
output AZURE_STORAGE_ACCOUNT_NAME string = storageAccount.outputs.storageAccountName
output AZURE_STORAGE_ACCOUNT_FILE_SHARE_NAME string = storageAccount.outputs.fileShareName
output AZURE_STORAGE_ACCOUNT_BLOB_CONTAINER_NAME string = storageAccount.outputs.blobContainerName
output AZURE_KEY_VAULT_NAME string = keyVault.outputs.keyVaultName
output AZURE_APP_INSIGHTS_NAME string = logging.outputs.appInsightsName
output AZURE_LOG_ANALYTICS_WORKSPACE_NAME string = logging.outputs.logAnalyticsWorkspaceName
output AZURE_MANAGED_IDENTITY_NAME string = managedIdentity.outputs.managedIdentityName

