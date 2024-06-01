# Index Sharepoint Files and Pages using Azure AI Search and Storage Accounts

This repository contains code and instructions for indexing files and pages from SharePoint into Azure AI Search using a Logic App and Function App and indexed from a Storage Account.

## Architecture

![Architecture](/assets/architecture.png)

## Setup and Deploy

First, establish required environment variables:

```powershell
$env:AZURE_ENV_NAME="sptoblob"
$env:AZURE_LOCATION="eastus"
$env:AZURE_CLIENT_ID="<value>"
$env:AZURE_TENANT_ID="<value>"
$env:AZURE_CLIENT_SECRET="<value>"
$env:SHAREPOINT_SITE_ID="<value>"
$env:SHAREPOINT_SITE_URL="<value>"
$env:SHAREPOINT_LIST_NAME="<value>"
$env:SHAREPOINT_USERNAME="<value>"
$env:SHAREPOINT_PASSWORD="<value>"
```

This project the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) to quickly deploy and tear down the resources and application files in Azure for demo purposes.

To get started, authenticate with an Azure Subscription.

```powershell
azd auth login
```

Alternatively, you can login to both CLIs via a service principal using the TenantId, ClientId, and Client secret. More information on that can be found at the following:

* [Azure CLI login with Service Princpal](https://learn.microsoft.com/en-us/cli/azure/authenticate-azure-cli-service-principal)
* [Azure Developer CLI Login](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/reference#azd-auth-login)

To provision the necessary Azure resoruces and deploy the application, run the UP command:

```powershell
azd up
```

Follow the prompts to name the environment (short project name like 'sptoblob') and select the necessary Subscription, Location, and Resource Group for deployment.

## Azure Resource Prerequisites

Until IaC and CI/CD automation is implemented, the following Azure resources will need to be provisioned:

1. Storage Account - Queue - name must be "sharepoint-pages"
2. Storage Account - Blob Container
3. App Service Plan
4. Function
5. Logic App - two workflows
6. AI Search - index, data source to blob container, and indexer
7. AI Service (for embeddings)
8. App Insights (recommended for Function and Logic App monitoring)

## Additional Prerequisites

1. Azure subscription and account with approprite permissions to create resources and deploy to Azure Functions and Logic Apps.
2. Visual Studio or VS Code with the [dotnet SDK](https://dotnet.microsoft.com/en-us/download).
3. Use an Azure tenant that can access Sharepoint
4. App registration with Microsoft Entra ID and given access to Graph. See [documentation here](https://learn.microsoft.com/en-us/graph/tutorials/dotnet-app-only?tabs=aad&tutorial-step=1)
5. Set lifecycle of blob container to [delete blobs after x days](https://learn.microsoft.com/en-us/azure/storage/blobs/lifecycle-management-policy-configure?tabs=azure-portal).

## Project Folder Descriptions

1. CreateAzureAIComponents: .NET console application to assist in provisioning and tearing down the Azure AI resources. Note: This solution is relatively temporary and will be superceded by standard IaC tools like Bicep/Terraform.
2. infra: IaC Bicep code - this is a work in progress
3. scripts: holds PS scripts to help with automation - this is a work in progress
4. src/Apps/SharepointToBlobFunctions: .NET Azure Function for processing Sharepoint Page contents and saving as HTML file. Triggered by a storage queue.
5. src/LogicApps: Logic App workflow json and other configuration. 2 apps - 1 to injest Sharepoint Files and one to injest Sharepoint Pages. Note: use the template json as a starting point as some of the configuration may not match up perfectly yet.

## Azure Function Configuration

Environment Variables needed on the Function App:

```powershell
AzureWebJobsStorage=#<storage account conn string>
AZURE_TENANT_ID=#<app registration tenant id>
AZURE_CLIENT_ID=#<app registration client id>
AZURE_CLIENT_SECRET=#<app registration secret>
AZURE_STORAGE_CONTAINER_NAME=#<name of blob container for index>
```

There are [few options for deploying the Azure Function available](https://learn.microsoft.com/en-us/azure/azure-functions/functions-deployment-technologies?tabs=windows).

## Clean Up Azure Resources

To remove the provisioned Resources run the following AZD command:

```powershell
azd down --force --purge
```

## Coming Soon

1. Infrastruction automation with (IaC) via Bicep
2. Deployment automation
3. Full process automation with the [Azure Developer CLI (AZD)](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview)
4. Indexing documentation
5. Process for initial batch-loading of files and pages

## License

This project is licensed under the [MIT License](LICENSE)
