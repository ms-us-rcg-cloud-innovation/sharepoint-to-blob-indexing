param location string
param appServicePlanName string
param logicAppName string
param managedIdentityName string
param logAnalyticsWorkspaceName string
param appInsightsName string
param keyVaultName string
param logicAppStorageAccountName string
param logicAppStorageAccountConnectionStringSecretName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2021-09-30-preview' existing = {
  name: managedIdentityName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: appInsightsName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'elastic'
  sku: {
    name: 'WS1'
  }
  properties: {
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: logicAppStorageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

var fileShareName = toLower(logicAppName)

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-04-01' = {
  name: '${storageAccount.name}/default/${fileShareName}'
}

resource storageAccountConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  name: '${keyVault.name}/${logicAppStorageAccountConnectionStringSecretName}'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'
  }
}

resource logicApp 'Microsoft.Web/sites@2021-02-01' = {
  name: logicAppName
  location: location
  kind: 'functionapp,workflowapp'
  dependsOn: [
    fileShare
    storageAccountConnectionStringSecret
  ]
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    keyVaultReferenceIdentity: managedIdentity.id
    httpsOnly: true
    siteConfig: {
      netFrameworkVersion: 'v4.0'
      functionsRuntimeScaleMonitoringEnabled: false
      appSettings: [

      ]
    }
  }
}

resource logicAppAppConfigSettings 'Microsoft.Web/sites/config@2022-03-01' = {
  name: 'appsettings'
  parent: logicApp
  properties: {
    APP_KIND: 'workflowApp'
    APPINSIGHTS_INSTRUMENTATIONKEY: appInsights.properties.InstrumentationKey
    APPLICATIONINSIGHTS_CONNECTION_STRING: appInsights.properties.ConnectionString
    ApplicationInsightsAgent_EXTENSION_VERSION: '~3'
    XDT_MicrosoftApplicationInsights_Mode: 'Recommended'
    FUNCTIONS_EXTENSION_VERSION: '~4'
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${logicAppStorageAccountConnectionStringSecretName})'
    FUNCTIONS_WORKER_RUNTIME: 'node'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${logicAppStorageAccountConnectionStringSecretName})'
    WEBSITE_CONTENTSHARE: fileShareName
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
  name: 'Logging'
  scope: logicApp
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'WorkflowRuntime'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output appServicePlanName string = appServicePlan.name
output logicAppName string = logicApp.name
output logicAppIdentityPrincipalId string = logicApp.identity.principalId
