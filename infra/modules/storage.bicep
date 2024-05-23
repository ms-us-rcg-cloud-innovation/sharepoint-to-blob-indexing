param storageLocation string
param storageName string

resource storageAcct 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageName
  location: storageLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

output storageAcctName string = storageAcct.name
