using './main.bicep'

param resourceGroupName = readEnvironmentVariable('AZURE_RG_NAME', 'rg-sptoblob')
param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'sptoblob')
param location = readEnvironmentVariable('AZURE_LOCATION', 'eastus')
