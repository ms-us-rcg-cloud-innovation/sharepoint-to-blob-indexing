targetScope = 'resourceGroup'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string = resourceGroup().location

@minLength(1)
@description('Name of existing resource group')
param resourceGroupName string

var abbrs = loadJsonContent('./abbreviations.json')

var tags = {
  'azd-env-name': environmentName
}

var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

module loggingDeployment 'modules/logging.bicep' = {
  name: 'logging-deployment'
  params: {
    appInsightsName: 'ain-${resourceToken}'
    logAnalyticsWorkspaceName: 'law-${resourceToken}'
    location: location
  }
}

module keyVaultDeployment 'modules/keyvault.bicep' = {
  name: 'key-vault-deployment'
  params: {
    keyVaultName: '${abbrs.keyVaultVaults}${resourceToken}' 
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    location: location
    managedIdentityName: managedIdentityDeployment.outputs.managedIdentityName
  }
}

module managedIdentityDeployment 'modules/managedidentity.bicep' = {
  name: 'managed-identity-deployment'
  params: {
    location: location
    managedIdentityName: '${abbrs.managedIdentityUserAssignedIdentities}${resourceToken}'
  }
}

module logicAppDeployment 'modules/logicapp.bicep' = {
  name: 'logic-app-deployment'
  params: {
    appInsightsName: loggingDeployment.outputs.appInsightsName
    logicAppName: '${abbrs.logicWorkflows}${resourceToken}'
    appServicePlanName: '${abbrs.webSitesAppService}${resourceToken}'
    keyVaultName: keyVaultDeployment.outputs.keyVaultName
    location: location
    logAnalyticsWorkspaceName: loggingDeployment.outputs.logAnalyticsWorkspaceName
    managedIdentityName: managedIdentityDeployment.outputs.managedIdentityName
    logicAppStorageAccountConnectionStringSecretName: 'logic-app-storage-account-connection-string'
    logicAppStorageAccountName: '${abbrs.storageStorageAccounts}${resourceToken}'
  }
}

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_SUBSCRIPTION_ID string = subscription().subscriptionId
output AZURE_RESOURCE_GROUP_NAME string =  resourceGroupName
output AZURE_LOGIC_APP_NAME string = logicAppDeployment.outputs.logicAppName
