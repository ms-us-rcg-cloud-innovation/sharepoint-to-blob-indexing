using System.Text.Json.Serialization;

namespace SharepointToBlobFunctions
{
    public class PageUpdatedQueueMessage
    {
        [JsonPropertyName("page_id")]
        public string? PageId { get; set; }

        [JsonPropertyName("site_id")]
        public string? SiteId { get; set; }

        public PageUpdatedContext ToContext()
        {
            if (string.IsNullOrWhiteSpace(PageId) || !Guid.TryParse(PageId, out Guid pageId))
                throw new InvalidOperationException("Invalid page id.");

            if (string.IsNullOrWhiteSpace(SiteId) || !Guid.TryParse(SiteId, out Guid siteId))
                throw new InvalidOperationException("Invalid site id.");

            return new PageUpdatedContext(pageId, siteId);
        }
    }
}
