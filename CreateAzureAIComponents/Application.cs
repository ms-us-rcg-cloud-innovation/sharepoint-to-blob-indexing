using CreateAzureAIComponents.Models;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Azure.Search.Documents.Indexes.Models;
using Azure.Search.Documents.Indexes;
using Azure.Search.Documents;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading.Tasks;
using Azure;
using static Azure.Search.Documents.Indexes.Models.LexicalAnalyzerName;
using System.Net.Http.Headers;
using System.Net.Http;

namespace CreateAzureAIComponents
{
    public class Application
    {
        private readonly ILogger<Application> _logger;
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;
        private readonly IOptions<AzureAISearchOptions> _searchOptions;
        private readonly IOptions<BlobOptions> _blobOptions;
        private readonly IOptions<OpenAIOptions> _openAIOptions;
        private readonly SearchIndexClient _indexClient;
        private readonly Uri _endpoint;
        private readonly AzureKeyCredential _credential;

        public Application(
            ILogger<Application> logger,
            HttpClient httpClient,
            IConfiguration configuration,
            IOptions<AzureAISearchOptions> searchOptions,
            IOptions<BlobOptions> blobOptions,
            IOptions<OpenAIOptions> openAIOptions)
        {
            _logger = logger;
            _httpClient = httpClient;
            _configuration = configuration;
            _searchOptions = searchOptions;
            _blobOptions = blobOptions;
            _openAIOptions = openAIOptions;

            _endpoint = new Uri(_searchOptions.Value.Endpoint);
            _credential = new AzureKeyCredential(_searchOptions.Value.Key);
            _indexClient = new SearchIndexClient(_endpoint, _credential);
        }
        public async Task CreateSearchObjects()
        {
            
            await DeleteSearchObject("indexer", _searchOptions.Value.IndexerName);
			await DeleteSearchObject("skillset", _searchOptions.Value.SkillsetName);
			await DeleteSearchObject("index", _searchOptions.Value.IndexName);

			await CreateSearchObject("datasource", _blobOptions.Value.AccountName);
			await CreateSearchObject("index", _searchOptions.Value.IndexName);
            await CreateSearchObject("skillset", _searchOptions.Value.SkillsetName);
            await CreateSearchObject("indexer", _searchOptions.Value.IndexerName);
        }

		private async Task DeleteSearchObject(string objectType, string objectName)
		{
			_logger.LogInformation($"Deleting {objectType}");
			var plural = $"{objectType}s";
			if (objectType == "index")
				plural = "indexes";

			var deletehUrl = $"https://{_searchOptions.Value.ServiceName}.search.windows.net/{plural}/{objectName}?api-version=2024-03-01-Preview";
			await CallDeleteRESTAPI(deletehUrl);
		}

		private async Task CallDeleteRESTAPI(string searchUrl)
		{
			using (var requestMessage =
						new HttpRequestMessage(HttpMethod.Delete, searchUrl))
			{
				requestMessage.Headers.Accept
								.Add(new MediaTypeWithQualityHeaderValue("application/json"));
				requestMessage.Headers.Add("api-key", _searchOptions.Value.Key);
				requestMessage.Headers.Add("User-Agent", "Console app");				
				var response = await _httpClient.SendAsync(requestMessage);
				if (response.IsSuccessStatusCode)
				{
					var jsonResponse = await response.Content.ReadAsStringAsync();
					_logger.LogInformation(jsonResponse);
				}
				else
				{
					_logger.LogError($"Error calling Azure Search API: {response.StatusCode} - {response.ReasonPhrase}");
				}
			}
		}

		public async Task CreateSearchObject(string objectType, string objectName)
        {
            try
            {
                // Do something epic
                _logger.LogInformation($"Creating {objectType}");
                var plural = $"{objectType}s";
                if (objectType == "index")
                    plural = "indexes";

                var appPath = Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
                var filePath = Path.Combine(appPath, $"api-payloads/{objectType}.json");
                string jsonSource = string.Empty;
                using (StreamReader r = new StreamReader(filePath))
                {
                    jsonSource = r.ReadToEnd();
                }

                string jsonMessage = ReplaceTokens(jsonSource);
                var searchUrl = $"https://{_searchOptions.Value.ServiceName}.search.windows.net/{plural}/{objectName}?api-version=2024-03-01-Preview";
                await CallSearchRESTAPI(jsonMessage, searchUrl);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex.Message);
            }

        }

        private async Task CallSearchRESTAPI(string jsonMessage, string searchUrl)
        {
                        HttpContent stringContent = new StringContent(jsonMessage, System.Text.Encoding.UTF8, "application/json");
            using (var requestMessage =
                        new HttpRequestMessage(HttpMethod.Put, searchUrl))
			{
				requestMessage.Headers.Accept
	                            .Add(new MediaTypeWithQualityHeaderValue("application/json"));				
                requestMessage.Headers.Add("api-key", _searchOptions.Value.Key);
                requestMessage.Headers.Add("User-Agent", "Console app");
                requestMessage.Content = stringContent;
                var response = await _httpClient.SendAsync(requestMessage);
                if (response.IsSuccessStatusCode)
                {
                    var jsonResponse = await response.Content.ReadAsStringAsync();
                    _logger.LogInformation(jsonResponse);
                }
                else
                {
                    _logger.LogError($"Error calling Azure Search API: {response.StatusCode} - {response.ReasonPhrase}");
                }
            }
        }

        private string ReplaceTokens(string jsonSource)
        {
            string results = jsonSource;
            results = results.Replace("OPENAI_ENDPOINT", _openAIOptions.Value.Endpoint);
            results = results.Replace("OPENAI_API_KEY", _openAIOptions.Value.Key);
            results = results.Replace("EMBEDDINGS_MODEL", _openAIOptions.Value.EmbeddingsDeployment);
            results = results.Replace("SEARCH_SERVICE_NAME", _searchOptions.Value.ServiceName);
            results = results.Replace("INDEX_NAME", _searchOptions.Value.IndexName);
            results = results.Replace("INDEXER_NAME", _searchOptions.Value.IndexerName);
            results = results.Replace("SKILLSET_NAME", _searchOptions.Value.SkillsetName);
            results = results.Replace("DATA_SOURCE_NAME", _blobOptions.Value.AccountName);
            results = results.Replace("BLOB_DESCRIPTION", _blobOptions.Value.BlobDescription);
            results = results.Replace("BLOB_ACCOUNT_NAME", _blobOptions.Value.AccountName);
            results = results.Replace("BLOB_CONNECTION_STRING", _blobOptions.Value.ConnectionString);
            results = results.Replace("BLOB_CONTAINER_NAME", _blobOptions.Value.ContainerName);
            return results;
        }
    }

}
