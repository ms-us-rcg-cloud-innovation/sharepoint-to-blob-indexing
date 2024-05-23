using Microsoft.Graph.Models;
using System.Text;

namespace SharepointToBlobFunctions
{
    public class WebPartsHtmlBuilder
    {
        private readonly IReadOnlyDictionary<string, IStandardWebPartHtmlHandler> _htmlHandlerLookup;

        public WebPartsHtmlBuilder(IReadOnlyDictionary<string, IStandardWebPartHtmlHandler> htmlHandlerLookup)
        {
            _htmlHandlerLookup = htmlHandlerLookup;
        }

        public async Task<string> BuildHtmlAsync(ICollection<WebPart>? webParts)
        {
            if (webParts == null)
                return string.Empty;

            StringBuilder htmlBuilder = new StringBuilder();

            foreach (var webpart in webParts)
            {
                if (webpart is TextWebPart textWebPart)
                {
                    if (!string.IsNullOrWhiteSpace(textWebPart.InnerHtml))
                        htmlBuilder.Append(textWebPart.InnerHtml);
                }
                else if (webpart is StandardWebPart standardWebPart)
                {
                    if (!string.IsNullOrWhiteSpace(standardWebPart.Data?.Title)
                        && _htmlHandlerLookup.TryGetValue(standardWebPart.Data.Title, out var handler))
                    {
                        var html = await handler.GetHtmlAsync(standardWebPart);
                        if (!string.IsNullOrWhiteSpace(html))
                            htmlBuilder.Append(html);
                    }
                }
            }
            
            return htmlBuilder.ToString();
        }
    }
}
