using Azure.Storage.Blobs;
using Microsoft.Graph.Models;
using System.Text;

namespace SharepointToBlobFunctions
{
    internal static class BlobContainerClientExtensions
    {
        public static async Task UploadHtmlAsync(this BlobContainerClient client, BaseSitePage page, string html)
        {
            if (page is null)
                throw new ArgumentNullException(nameof(page));

            if (string.IsNullOrWhiteSpace(html))
                throw new ArgumentNullException(nameof(html));

            var blobClient = client.GetBlobClient($"{page.Id}.html");

            using var stream = new MemoryStream(Encoding.UTF8.GetBytes(html));
            
            await blobClient.UploadAsync(stream, metadata: new Dictionary<string, string>
            {
                { "sourceuri", page.WebUrl ?? "" },
            }, conditions: null);
        }
    }
}
