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
