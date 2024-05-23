using Microsoft.Graph.Models;
using System.Text;

namespace SharepointToBlobFunctions
{
    public class ImageWebPartHtmlHandler : IStandardWebPartHtmlHandler
    {
        public string Title => "Image";

        public Task<string> GetHtmlAsync(StandardWebPart webPart)
        {
            string? imgSrc = string.Empty;
            string? altText = string.Empty;
            string? captionText = string.Empty;

            if (webPart.Data?.Properties == null)
                return Task.FromResult(string.Empty);

            if (webPart.Data.Properties.AdditionalData.TryGetValue("fileName", out var imgSrcValue))
                imgSrc = imgSrcValue as string;

            if (webPart.Data.Properties.AdditionalData.TryGetValue("altText", out var altTextValue))
                altText = altTextValue as string;

            if (webPart.Data.Properties.AdditionalData.TryGetValue("captionText", out var captionTextValue))
                captionText = captionTextValue as string;

            if (string.IsNullOrWhiteSpace(imgSrc) && string.IsNullOrWhiteSpace(altText) && string.IsNullOrWhiteSpace(captionText))
                return Task.FromResult(string.Empty);

            var htmlBuilder = new StringBuilder();
            htmlBuilder.Append("<figure>");
            htmlBuilder.Append("<img src=\"");
            htmlBuilder.Append(imgSrc);
            htmlBuilder.Append("\"");

            if (!string.IsNullOrWhiteSpace(altText))
            {
                htmlBuilder.Append(" alt=\"");
                htmlBuilder.Append(altText);
                htmlBuilder.Append("\"");
            }

            htmlBuilder.Append(">");

            if (!string.IsNullOrWhiteSpace(captionText))
            {
                htmlBuilder.Append("<figcaption>");
                htmlBuilder.Append(captionText);
                htmlBuilder.Append("</figcaption>");
            }

            htmlBuilder.Append("</figure>");

            return Task.FromResult(htmlBuilder.ToString());
        }
    }
}
