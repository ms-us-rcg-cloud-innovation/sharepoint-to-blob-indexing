# Index Sharepoint Files and Pages using Azure AI Search and Storage Accounts

This repository contains code and instructions for indexing files and pages from SharePoint into Azure AI Search using a Logic App and Function App and indexed from a Storage Account.

## Architecture

![Architecture](/assets/architecture.png)

## Project Folder Descriptions

1. CreateAzureAIComponents: .NET console application to assist in provisioning and tearing down the Azure AI resources. Note: This solution is relatively temporary and will be superceded by standard IaC tools like Bicep/Terraform.
2. infra: IaC Bicep code to deploy Azure resources
3. scripts: holds PS scripts to help with automation
4. src/Apps/SharepointToBlobFunctions: .NET Azure Function for processing Sharepoint Page contents and saving as HTML file. Triggered by a storage queue.
5. src/LogicApps: Logic App workflow json and other configuration. 2 apps - 1 to injest Sharepoint Files and one to injest Sharepoint Pages.

## Prerequisites

1. Azure Subscription and Entra ID Account with approprite permissions to create resources and deploy applications to Azure Functions and Logic Apps.
2. A Sharepoint Online site and account with permissions to create pages and add/edit files in a given folder/list.
3. App registration with Microsoft Entra ID and given access to Graph. See [documentation here](https://learn.microsoft.com/en-us/graph/tutorials/dotnet-app-only?tabs=aad&tutorial-step=1). Note the tenant id, client id, client secret.

## Setup

### Check Environment

Run the CheckEnvironment.ps1 script to ensure the latest CLIs and dependencies are installed. If any dependencies are missing, the script will output guidance on how to install.

```powershell
cd scripts
.\CheckEnvironment.ps1
```

### Deploy

Establish required environment variables:

```powershell
$env:AZURE_ENV_NAME="sptoblob" # custom project name
$env:AZURE_LOCATION="eastus" # azure region

# app registration connection with Graph access
$env:AZURE_SHAREPOINT_GRAPH_CLIENT_ID="<value>" 
$env:AZURE_SHAREPOINT_GRAPH_TENANT_ID="<value>"
$env:AZURE_SHAREPOINT_GRAPH_CLIENT_SECRET="<value>"

# sharepoint connection info
$env:SHAREPOINT_SITE_ID="<value>" # unique guid for the site
$env:SHAREPOINT_SITE_URL="<value>" # url to sharepoint site
$env:SHAREPOINT_LIST_NAME="<value>" # list / folder name to monitor for indexing
$env:SHAREPOINT_USERNAME="<value>" # account username
$env:SHAREPOINT_PASSWORD="<value>" # account password
```

This project uses the [Azure Developer CLI](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/overview) to quickly deploy and tear down the resources and application files in Azure for demo purposes.

To get started, authenticate with an Azure Subscription ([details](https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/reference#azd-auth-login)):

```powershell
azd auth login
```

To provision the necessary Azure resoruces and deploy the application, run the UP command:

```powershell
azd up
```

Once the infrastructure is established and the application is deployed, navigate to the [Azure Portal](https://portal.azure.com) to view the provisioned resources.

### Additional Setup Requirements

In the Azure Portal, navigate to API Connections, select the 'sharepoint-online' connection, select to Edit API Connection, and click Authorize. In the dialog window, authenticate with credentials that have access to a Sharepoint Online instance. Once authentication is successful, click Save on the Edit API Connection screen to persist the auth values with the API Connection.

## Verify

Verify the application by adding/editing files in the provided list/folder name in Sharepoint and then verifying the 'sp-file-to-blob' Logic App Workflow is triggered. This will place the file in the 'sptoblobcontainer' Container in the Storage Account. An Azure AI Search Indexer will run every few minutes and index the file from the Storage Account. A Lifecycle Management Rule will remove all files in the container after 1 day.

A similar process applies to Pages in Sharepoint. Add/edit pages in the 'Site Pages' list to have those changes automatically indexed. The 'sp-page-to-blob' Logic App Workflow is triggered and will store the Sharepoint Site Id (from configuration) and the updated/added Page Id in an Azure Storage Queue message. An Azure Function will pick up this message. The function will query Microsoft Graph API to pull the Page's details as well as the Page's Webparts. Using this Page data, the function will build out the Page as raw HTML and save to the Container for indexing.

## Clean Up Azure Resources

To remove the provisioned Resources run the following AZD command:

```powershell
azd down --force --purge
```

## Coming Soon

1. Process for initial batch-loading of files and pages

## License

This project is licensed under the [MIT License](LICENSE)
