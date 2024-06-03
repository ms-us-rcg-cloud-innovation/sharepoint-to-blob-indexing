@description('Required. Name of the existing OpenAI Account') 
@maxLength(64)
param openAiName string

@description('Required. Deployment Name can have only letters and numbers, no spaces. Hyphens ("-") and underscores ("_") may be used, except as ending characters.')
@minLength(2)
@maxLength(64)
param deploymentName string

param modelName string
param modelVersion string

resource openAi 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAiName
}

resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  name: deploymentName
  parent: openAi 
  sku: {
    name: 'Standard'
    capacity: 1
  }
  properties: {
    raiPolicyName: 'Microsoft.Default'
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
  }
}

output deploymentId string = modelDeployment.id
output deploymentName string = modelDeployment.name
