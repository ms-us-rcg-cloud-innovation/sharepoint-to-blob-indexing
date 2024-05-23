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

                var page = await pageQueryBuilder.GetAsync();
                if (page is null)
                {
                    _logger.LogWarning("Page with id {pageId} and SiteId {siteId} not found.", context.PageId, context.SiteId);
                    return;
                }

                _logger.LogDebug("Page Details:");
                _logger.LogDebug("Id: {page.Id}", page.Id);
                _logger.LogDebug("Title: {page.Title}", page.Title);
                _logger.LogDebug("Name: {page.Name}", page.Name);
                _logger.LogDebug("Link: {page.WebUrl}", page.WebUrl);
                _logger.LogDebug("ETag: {page.ETag}", page.ETag);

                var webPartsResponse = await pageQueryBuilder.GraphSitePage.WebParts.GetAsync();

                string bodyHtml = await _webPartsHtmlBuilder.BuildHtmlAsync(webPartsResponse?.Value);

                var htmlDoc = new HtmlDocument();

                var headNode = HtmlNode.CreateNode("<head></head>")
                                       .SetHeaderContent(page);        

                htmlDoc.DocumentNode.AppendChild(headNode);

                var bodyNode = HtmlNode.CreateNode("<body></body>")
                                       .SetBodyContent(page, bodyHtml);

                htmlDoc.DocumentNode.AppendChild(bodyNode);

                var html = htmlDoc.DocumentNode.WriteTo();

                await _blobContainerClient.UploadHtmlAsync(page, html);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, ex.Message);
            }
        }
    }
}
