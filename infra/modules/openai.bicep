@description('Required. Name of the OpenAI Account. Must be globally unique. Only alphanumeric characters and hyphens are allowed. The value must be 2-64 characters long and cannot start or end with a hyphen') 
@maxLength(64)
@minLength(2)
param name string

param location string
param tags object = {}

param managedIdentityName string
param logAnalyticsWorkspaceName string
param keyVaultName string

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource cognitiveServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  kind: 'OpenAI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  location: location
  tags: tags
  sku: {
    name: 'S0'
  }
  properties: {
    // networkAcls: !empty(networkAcls) ? {
    //   defaultAction: contains(networkAcls, 'defaultAction') ? networkAcls.defaultAction : null
    //   virtualNetworkRules: contains(networkAcls, 'virtualNetworkRules') ? networkAcls.virtualNetworkRules : []
    //   ipRules: contains(networkAcls, 'ipRules') ? networkAcls.ipRules : []
    // } : null
   
    publicNetworkAccess: 'Enabled'
    //allowedFqdnList: allowedFqdnList
    disableLocalAuth: true
    restore: false
    //restrictOutboundNetworkAccess: restrictOutboundNetworkAccess
    //userOwnedStorage: !empty(userOwnedStorage) ? userOwnedStorage : null
    dynamicThrottlingEnabled: false
  }
}

resource diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = {
  name: 'OpenAI-Cognitive-Services'
  scope: cognitiveServices
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'Audit'
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

@description('This is the built-in Cognitive Services User role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#security')
resource cogServicesUserRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'a97b65f3-24c7-4388-baec-2e87135dc908'
}

resource cogServicesUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(cognitiveServices.id, managedIdentity.id, cogServicesUserRoleDefinition.id)
  scope: cognitiveServices
  properties: {
    roleDefinitionId: cogServicesUserRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource openAIKeySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'openai-key'
  properties: {
    value: cognitiveServices.listKeys().key1
  }
}

output name string = cognitiveServices.name
output endpoint string = 'https://${cognitiveServices.name}.openai.azure.com'
output keySecretName string = openAIKeySecret.name
