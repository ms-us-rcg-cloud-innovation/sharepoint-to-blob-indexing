using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME')
param location = readEnvironmentVariable('AZURE_LOCATION')

param clientId = readEnvironmentVariable('AZURE_CLIENT_ID')
param tenantId = readEnvironmentVariable('AZURE_TENANT_ID')
param clientSecret = readEnvironmentVariable('AZURE_CLIENT_SECRET')

param sharepointSiteId =  readEnvironmentVariable('SHAREPOINT_SITE_ID')
param sharepointSiteUrl =  readEnvironmentVariable('SHAREPOINT_SITE_URL')
param sharepointListName =  readEnvironmentVariable('SHAREPOINT_LIST_NAME')

param sharepointUserName =  readEnvironmentVariable('SHAREPOINT_USERNAME')
param sharepointPassword =  readEnvironmentVariable('SHAREPOINT_PASSWORD')
