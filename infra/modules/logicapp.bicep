param location string
param appServicePlanName string
param name string
param managedIdentityName string
param logAnalyticsWorkspaceName string
param appInsightsName string
param keyVaultName string
param fileShareName string
param storageAcctConnStringName string
param tags object

param sharepointSiteUrl string
param sharepointListName string

param sharepointConnectionName string
param azureQueueConnectionName string
param azureBlobConnectionName string

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

resource sharepointConnection 'Microsoft.Web/connections@2016-06-01' existing = {
  name: sharepointConnectionName
}

resource azureQueueConnection 'Microsoft.Web/connections@2016-06-01' existing = {
  name: azureQueueConnectionName
}

resource azureBlobConnection 'Microsoft.Web/connections@2016-06-01' existing = {
  name: azureBlobConnectionName
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

resource logicApp 'Microsoft.Web/sites@2021-02-01' = {
  name: name
  location: location
  kind: 'functionapp,workflowapp'
  tags: tags
  identity: {
    type: 'UserAssigned'
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
    AzureWebJobsStorage: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${storageAcctConnStringName})'
    FUNCTIONS_WORKER_RUNTIME: 'node'
    WEBSITE_CONTENTAZUREFILECONNECTIONSTRING: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${storageAcctConnStringName})'
    WEBSITE_CONTENTSHARE: fileShareName
    SHAREPOINT_SITE_URL: sharepointSiteUrl
    SHAREPOINT_LIST_NAME: sharepointListName  
    SHAREPOINT_CONNECTION_API_ID: sharepointConnection.properties.api.id
    SHAREPOINT_CONNECTION_RESOURCE_ID: sharepointConnection.id
    SHAREPOINT_CONNECTION_RUNTIME_URL: sharepointConnection.properties.connectionRuntimeUrl
    AZURE_STORAGE_ACCOUNT_QUEUE_RESOURCE_ID: azureQueueConnection.id
    AZURE_STORAGE_ACCOUNT_QUEUE_APP_ID: azureQueueConnection.properties.api.id
    AZURE_STORAGE_ACCOUNT_QUEUE_RUNTIME_URL: azureQueueConnection.properties.connectionRuntimeUrl
    AZURE_STORAGE_ACCOUNT_BLOB_RESOURCE_ID: azureBlobConnection.id
    AZURE_STORAGE_ACCOUNT_BLOB_APP_ID: azureBlobConnection.properties.api.id
    AZURE_STORAGE_ACCOUNT_BLOB_RUNTIME_URL: azureBlobConnection.properties.connectionRuntimeUrl
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

output logicAppName string = logicApp.name
