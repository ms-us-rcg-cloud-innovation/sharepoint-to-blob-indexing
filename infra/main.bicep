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
param tenantId string

@minLength(1)
@description('Client Id for MS Graph app registration')
param clientId string

@secure()
@minLength(1)
@description('Client Secret for MS Graph app registration')
param clientSecret string

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

var storageAccountConnStringSecretName = 'sa-conn-string'
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
    tenantId: tenantId
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
    managedIdentityName: managedIdentity.outputs.managedIdentityName
  }
}

module storageAccount 'modules/storage.bicep' = {
  name: 'storage-account-${environmentName}-deployment'
  scope: rg
  params: {
    name: 'sa${resourceToken}'
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    keyVaultName: keyVault.outputs.keyVaultName
    connStringSecretName: storageAccountConnStringSecretName
  }
}

module openAI 'modules/openai.bicep' = {
  name: 'openai-${environmentName}-deployment'
  scope: rg
  params: {
    name: 'ai-${resourceToken}'
    location: location
    tags: tags
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    logAnalyticsWorkspaceName: logging.outputs.logAnalyticsWorkspaceName
  }
}

module aiModelDeployment  'modules/openaideployment.bicep' = {
    name: 'ai-model-${environmentName}-deployment'
    scope: rg
    dependsOn:[
      openAI
    ]
    params: {
      openAiName: openAI.outputs.name
      deploymentName: 'ai-model-${resourceToken}'
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

module sharepointConnection 'modules/connection.bicep' = {
  name: 'sharepoint-conn-${environmentName}-deployment'
  scope: rg
  params: {
    location: location
    tags: tags
    apiName: 'sharepointonline'
    connectionName: 'sharepointonline'
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    parameters: {
      UserName: sharepointUserName
      Password: sharepointPassword
    }
  }
}

module azureQueueConnection 'modules/connection.bicep' = {
  name: 'azure-queue-conn-${environmentName}-deployment'
  scope: rg
  dependsOn: [
    storageAccount
    keyVault
  ]
  params: {
    location: location
    tags: tags
    apiName: 'azurequeues'
    connectionName: 'azurequeues'
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    parameters: {
      StorageAccount: storageAccount.outputs.storageAccountName
      SharedKey: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${storageAccountConnStringSecretName})'
    }
  }
}

module azureBlobConnection 'modules/connection.bicep' = {
  name: 'azure-blob-conn-${environmentName}-deployment'
  scope: rg
  dependsOn: [
    storageAccount
    keyVault
  ]
  params: {
    location: location
    tags: tags
    apiName: 'azureblob'
    connectionName: 'azureblob'
    managedIdentityName: managedIdentity.outputs.managedIdentityName
    parameters: {
      AccountName: storageAccount.outputs.storageAccountName
      AccessKey: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${storageAccountConnStringSecretName})'
    }
  }
}

module logicApp 'modules/logicapp.bicep' = {
  name: 'logic-app-${environmentName}-deployment'
  scope: rg
  dependsOn: [
    managedIdentity
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
    storageAcctConnStringName: storageAccountConnStringSecretName
    fileShareName: storageAccount.outputs.fileShareName
    sharepointSiteUrl: sharepointSiteUrl
    sharepointListName: sharepointListName
    sharepointConnectionName: sharepointConnection.outputs.name
    azureQueueConnectionName: azureQueueConnection.outputs.name
    azureBlobConnectionName: azureBlobConnection.outputs.name
  }
}

module functionApp 'modules/functionapp.bicep' = {
  name: 'function-app-${environmentName}-deployment'
  scope: rg
  dependsOn: [
    managedIdentity
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
    storageAcctConnStringName: storageAccountConnStringSecretName
    fileShareName: storageAccount.outputs.fileShareName
    tenantId: tenantId 
    clientId: clientId 
    clientSecret: clientSecret
    storageAcctContainerName: storageAccount.outputs.blobContainerName
    sharepointSiteId: sharepointSiteId
  }
}

output AZURE_RESOURCE_GROUP_NAME string = rg.name
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenantId
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

