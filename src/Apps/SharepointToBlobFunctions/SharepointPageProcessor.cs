using Azure.Storage.Blobs;
using HtmlAgilityPack;
using Microsoft.Extensions.Logging;
using Microsoft.Graph;

namespace SharepointToBlobFunctions
{
    public class SharepointPageProcessor
    {
        private readonly GraphServiceClient _graphServiceClient;
        private readonly BlobContainerClient _blobContainerClient;
        private readonly WebPartsHtmlBuilder _webPartsHtmlBuilder;
        private readonly ILogger<SharepointPageProcessor> _logger;

        public SharepointPageProcessor(
            GraphServiceClient graphServiceClient,
            BlobContainerClient blobContainerClient,
            WebPartsHtmlBuilder webPartsHtmlBuilder,
            ILogger<SharepointPageProcessor> logger)
        {
            _graphServiceClient = graphServiceClient;
            _blobContainerClient = blobContainerClient;
            _webPartsHtmlBuilder = webPartsHtmlBuilder;
            _logger = logger;
        }

        public async Task ProcessAsync(PageUpdatedContext context)
        {
            try
            {
                if (context is null)
                    throw new ArgumentNullException(nameof(context));

                var pageQueryBuilder = _graphServiceClient.Sites[context.SiteId.ToString()].Pages[context.PageId.ToString()];

                _logger.LogInformation("Processing page with id {pageId} and SiteId {siteId}.", context.PageId, context.SiteId);
                _logger.LogInformation("Retrieving page details...");
                
                var page = await pageQueryBuilder.GetAsync();
                if (page is null)
                {
                    _logger.LogWarning("Page with id {pageId} and SiteId {siteId} not found.", context.PageId, context.SiteId);
                    return;
                }

                _logger.LogInformation("Page Found - Title: {pageTitle}, Name: {pageName}, Link: {pageLink}, ETag: {pageETag}", page.Title, page.Name, page.WebUrl, page.ETag);
                _logger.LogInformation("Retrieving web parts...");
                
                var webPartsResponse = await pageQueryBuilder.GraphSitePage.WebParts.GetAsync();

                _logger.LogInformation("{webPartsCount} Web Parts found.", webPartsResponse?.Value?.Count ?? 0);
                _logger.LogInformation("Building HTML...");
                
                string bodyHtml = await _webPartsHtmlBuilder.BuildHtmlAsync(webPartsResponse?.Value);

                var htmlDoc = new HtmlDocument();

                var headNode = HtmlNode.CreateNode("<head></head>")
                                       .SetHeaderContent(page);        

                htmlDoc.DocumentNode.AppendChild(headNode);

                var bodyNode = HtmlNode.CreateNode("<body></body>")
                                       .SetBodyContent(page, bodyHtml);

                htmlDoc.DocumentNode.AppendChild(bodyNode);

                var html = htmlDoc.DocumentNode.WriteTo();

                _logger.LogInformation("Uploading HTML file to blob storage...");

                await _blobContainerClient.UploadHtmlAsync(page, html);

                _logger.LogInformation("HTML file uploaded successfully.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, ex.Message);
            }
        }
    }
}
