using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME')

param clientId = readEnvironmentVariable('AZURE_CLIENT_ID')
param tenantId = readEnvironmentVariable('AZURE_TENANT_ID')
param clientSecret = readEnvironmentVariable('AZURE_CLIENT_SECRET')

param sharepointSiteId =  readEnvironmentVariable('SHAREPOINT_SITE_ID')
