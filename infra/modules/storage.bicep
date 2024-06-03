param location string
param name string
param tags object
param keyVaultName string
param managedIdentityName string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: managedIdentityName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {
  }
}

resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  parent: fileServices
  name: 'sptoblobshare'
  properties: {}
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {}
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  parent: blobServices
  name: 'sptoblobcontainer'
  properties: {}
}

resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
  properties: {}
}

resource queue 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01' = {
  parent: queueServices
  name: 'sharepoint-pages'
  properties: {}
}

var accountKey = storageAccount.listKeys().keys[0].value

resource storageAccountConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'sa-conn-string'
  properties: {
    value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${accountKey}'
  }
}

resource storageAccountKeySecret 'Microsoft.KeyVault/vaults/secrets@2022-07-01' = {
  parent: keyVault
  name: 'sa-key'
  properties: {
    value: accountKey
  }
}

@description('This is the built-in Storage Blob Data Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#security')
resource storageBlobDataContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

@description('This is the built-in Storage Queue Data Contributor role. See https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#security')
resource storageQueueDataContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
}

resource blobDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(storageAccount.id, managedIdentity.id, storageBlobDataContributorRoleDefinition.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource queueDataContributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(storageAccount.id, managedIdentity.id, storageQueueDataContributorRoleDefinition.id)
  scope: storageAccount
  properties: {
    roleDefinitionId: storageQueueDataContributorRoleDefinition.id
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output storageAccountName string = storageAccount.name
output fileShareName string = fileShare.name
output blobContainerName string = blobContainer.name
output connStringSecretName string = storageAccountConnectionStringSecret.name
output keySecretName string = storageAccountKeySecret.name

