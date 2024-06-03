param(
    [string] [Parameter(Mandatory=$true)] $searchServiceName,
    [string] [Parameter(Mandatory=$true)] $dataSourceName,
    [string] [Parameter(Mandatory=$true)] $searchIndexName,
    [string] [Parameter(Mandatory=$true)] $searchIndexerName,
    [string] [Parameter(Mandatory=$true)] $skillsetName,
    [string] [Parameter(Mandatory=$true)] $storageAccountName,
    [string] [Parameter(Mandatory=$true)] $storageContainerName,
    [string] [Parameter(Mandatory=$true)] $storageConnString,
    [string] [Parameter(Mandatory=$true)] $openAIEndpoint,
    [string] [Parameter(Mandatory=$true)] $openAIEmbeddingsModel,
    [string] [Parameter(Mandatory=$true)] $openAIKey
)

$ErrorActionPreference = 'Stop'

$apiversion = '2024-03-01-preview'
# http://169.254.169.254/metadata/identity/oauth2/token
# Invoke-WebRequest -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=$apiversion&resource=https%3A%2F%search.azure.com%2F" -Headers @{ Metadata="true" }
# $content =$response.Content | ConvertFrom-Json
# $token = $content.access_token

$token = Get-AzAccessToken -ResourceUrl "https://search.azure.com"
$access_token = $token.Token

$headers = @{ 'Authorization' = "Bearer $access_token"; 'Content-Type' = 'application/json'; }
$uri = "https://$searchServiceName.search.windows.net"

$DeploymentScriptOutputs = @{}

$skillsetPayloadJson = @"
{
  "name": "$skillsetName",
  "description": "Split and chunk documents",
  "skills": [
    {
      "@odata.type": "#Microsoft.Skills.Text.SplitSkill",
      "name": "#1",
      "description": "Split skill to chunk documents",
      "context": "/document",
      "defaultLanguageCode": "en",
      "textSplitMode": "pages",
      "maximumPageLength": 1000,
      "pageOverlapLength": 450,
      "maximumPagesToTake": 0,
      "inputs": [
        {
          "name": "text",
          "source": "/document/content"
        }
      ],
      "outputs": [
        {
          "name": "textItems",
          "targetName": "chunks"
        }
      ]
    },
    {
        "@odata.type": "#Microsoft.Skills.Text.AzureOpenAIEmbeddingSkill",
        "name": "#3",
        "description": null,
        "context": "/document/chunks/*",
        "resourceUri": "$openAIEndpoint",
        "apiKey": "$openAIKey",
        "deploymentId": "$openAIEmbeddingsModel",
        "inputs": [
            {
            "name": "text",
            "source": "/document/chunks/*"
            }
        ],
        "outputs": [
            {
            "name": "embedding",
            "targetName": "vector"
            }
        ],
        "authIdentity": null
    }
  ]
}
"@

$dataSourcePayloadJson = @"
{
  "name": "$dataSourceName",
  "description": "Container $storageContainerName in Storage account $storageAccountName",
  "type": "azureblob",
  "credentials": {
    "connectionString": "$storageConnString"
  },
  "container": {
    "name": "$storageContainerName"
  }
}
"@

$indexPayloadJson = @"
{
    "name": "$searchIndexName",
    "defaultScoringProfile": "",
    "fields": [
        {
            "name": "ParentKey",
            "type": "Edm.String",
            "searchable": true,
            "filterable": true,
            "retrievable": true,
            "sortable": false,
            "facetable": false,
            "key": false,
            "indexAnalyzer": null,
            "searchAnalyzer": null,
            "analyzer": "standard.lucene",
            "synonymMaps": []
        },  
        {
            "name": "key",
            "type": "Edm.String",
            "searchable": true,
            "filterable": true,
            "retrievable": true,
            "sortable": false,
            "facetable": false,
            "key": true,
            "indexAnalyzer": null,
            "searchAnalyzer": null,
            "analyzer": "keyword",
            "synonymMaps": []
        },  
        {
            "name": "chunk",
            "type": "Edm.String",
            "searchable": true,
            "filterable": false,
            "retrievable": true,
            "sortable": false,
            "facetable": false,
            "key": false,
            "indexAnalyzer": null,
            "searchAnalyzer": null,
            "analyzer": "standard.lucene",
            "synonymMaps": []
        },
        {
            "name": "sourceuri",
            "type": "Edm.String",
            "searchable": true,
            "filterable": true,
            "retrievable": true,
            "sortable": false,
            "facetable": false,
            "key": false,
            "indexAnalyzer": null,
            "searchAnalyzer": null,
            "analyzer": null,
            "synonymMaps": []
        },    
        {
            "name": "chunkVector",
            "type": "Collection(Edm.Single)",
            "searchable": true,
            "filterable": false,
            "retrievable": true,
            "sortable": false,
            "facetable": false,
            "key": false,
            "indexAnalyzer": null,
            "searchAnalyzer": null,
            "analyzer": null,
            "dimensions": 1536,
            "vectorSearchProfile": "manuals-profile",
            "synonymMaps": []
        }
    ],
    "scoringProfiles": [],
    "corsOptions": null,
    "suggesters": [],
    "analyzers": [],
    "tokenizers": [],
    "tokenFilters": [],
    "charFilters": [],
    "encryptionKey": null,
    "similarity": {
        "@odata.type": "#Microsoft.Azure.Search.BM25Similarity",
        "k1": null,
        "b": null
    },
    "semantic": {
        "defaultConfiguration": "manuals-semantic-configuration",
        "configurations": [
            {
                "name": "manuals-semantic-configuration",
                "prioritizedFields": {
                    "titleField": {
                        "fieldName": "sourceuri"
                    },
                    "prioritizedContentFields": [
                        {
                        "fieldName": "chunk"
                        }
                    ],
                    "prioritizedKeywordsFields": []
                }
            }
        ]
    },
    "vectorSearch": {
        "algorithms": [
            {
                "name": "manuals-algorithm",
                "kind": "hnsw",
                "hnswParameters": {
                    "metric": "cosine",
                    "m": 4,
                    "efConstruction": 400,
                    "efSearch": 500
                },
                "exhaustiveKnnParameters": null
            }
        ],
        "profiles": [
            {
                "name": "manuals-profile",
                "algorithm": "manuals-algorithm",
                "vectorizer": "manuals-vectorizer",
                "compression": null
            }
        ],
        "vectorizers": [
            {
                "name": "manuals-vectorizer",
                "kind": "azureOpenAI",
                "azureOpenAIParameters": {
                    "resourceUri": "$openAIEndpoint",
                    "deploymentId": "$openAIEmbeddingsModel",
                    "apiKey": "$openAIKey",
                    "authIdentity": null
                },
                "customWebApiParameters": null
            }
        ],
        "compressions": []
    }
}
"@

$indexerPayloadJson = @"
{
    "name": "$searchIndexerName",
    "description": "",
    "dataSourceName": "$dataSourceName",
    "skillsetName": "$skillsetName",
    "targetIndexName": "$searchIndexName",
    "disabled": null,
    "schedule": {
      "interval": "PT10M",
      "startTime": "2024-01-01T00:00:00Z"
    },
    "parameters": {
      "batchSize": null,
      "maxFailedItems": 0,
      "maxFailedItemsPerBatch": 0,
      "base64EncodeKeys": null,
      "configuration": {
        "dataToExtract": "contentAndMetadata",
        "parsingMode": "default"
      }
    },
	"fieldMappings": [
		{
		  "sourceFieldName": "sourceuri",
		  "targetFieldName": "sourceuri"
		}
	],
    "encryptionKey": null
}

"@

$DeploymentScriptOutputs['indexName'] = $searchIndexName


try {
    # https://learn.microsoft.com/rest/api/searchservice/create-index
    Invoke-WebRequest `
        -Method 'PUT' `
        -Uri "$uri/indexes('$searchIndexName')?api-version=$apiversion" `
        -Headers  $headers `
        -Body $indexPayloadJson

    # https://learn.microsoft.com/rest/api/searchservice/create-data-source
    Invoke-WebRequest `
        -Method 'PUT' `
        -Uri "$uri/datasources('$dataSourceName')?api-version=$apiversion" `
        -Headers $headers `
        -Body $dataSourcePayloadJson

    # https://learn.microsoft.com/en-us/rest/api/searchservice/create-skillset
    Invoke-WebRequest `
        -Method 'PUT' `
        -Uri "$uri/skillsets('$skillsetName')?api-version=$apiversion" `
        -Headers $headers `
        -Body $skillsetPayloadJson

    # https://learn.microsoft.com/rest/api/searchservice/create-indexer
    Invoke-WebRequest `
        -Method 'PUT' `
        -Uri "$uri/indexers('$searchIndexerName')?api-version=$apiversion" `
        -Headers $headers `
        -Body $indexerPayloadJson
    
} catch {
    Write-Error $_.ErrorDetails.Message
    throw
}