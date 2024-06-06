using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME')
param location = readEnvironmentVariable('AZURE_LOCATION')

param sharepointGraphClientId = readEnvironmentVariable('AZURE_SHAREPOINT_GRAPH_CLIENT_ID')
param sharepointGraphTenantId = readEnvironmentVariable('AZURE_SHAREPOINT_GRAPH_TENANT_ID')
param sharepointGraphClientSecret = readEnvironmentVariable('AZURE_SHAREPOINT_GRAPH_CLIENT_SECRET')

param sharepointSiteId =  readEnvironmentVariable('SHAREPOINT_SITE_ID')
param sharepointSiteUrl =  readEnvironmentVariable('SHAREPOINT_SITE_URL')
param sharepointListName =  readEnvironmentVariable('SHAREPOINT_LIST_NAME')
