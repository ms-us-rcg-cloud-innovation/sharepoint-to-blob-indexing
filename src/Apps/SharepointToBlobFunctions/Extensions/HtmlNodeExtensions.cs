using HtmlAgilityPack;
using Microsoft.Graph.Models;

namespace SharepointToBlobFunctions
{
    internal static class HtmlNodeExtensions
    {
        public static HtmlNode SetHeaderContent(this HtmlNode node, BaseSitePage page)
        {
            if (page is null)
                throw new ArgumentNullException(nameof(page));

            if (!string.IsNullOrWhiteSpace(page.Title))
            {
                var metaTitleNode = HtmlNode.CreateNode($"<title>{page.Title}</title>");
                node.AppendChild(metaTitleNode);
            }

            if (!string.IsNullOrWhiteSpace(page.Description))
            {
                var metaDescNode = HtmlNode.CreateNode($"<meta name=\"description\" content=\"{page.Description}\" />");
                node.AppendChild(metaDescNode);
            }

            if (!string.IsNullOrWhiteSpace(page.LastModifiedBy?.User?.DisplayName))
            {
                var metaAuthorNode = HtmlNode.CreateNode($"<meta name=\"author\" content=\"{page.LastModifiedBy?.User?.DisplayName}\" />");
                node.AppendChild(metaAuthorNode);
            }

            return node;
        }

        public static HtmlNode SetBodyContent(this HtmlNode node, BaseSitePage page, string bodyHtml)
        {
            if (!string.IsNullOrWhiteSpace(page.Title))
            {
                var titleNode = HtmlNode.CreateNode($"<h1>{page.Title}</h1>");
                node.AppendChild(titleNode);
            }

            if (!string.IsNullOrWhiteSpace(page.LastModifiedBy?.User?.DisplayName))
            {
                var authorNode = HtmlNode.CreateNode($"<p>Author: {page.LastModifiedBy?.User?.DisplayName}</p>");
                node.AppendChild(authorNode);
            }

            if (!string.IsNullOrWhiteSpace(page.Description))
            {
                var descNode = HtmlNode.CreateNode($"<p>{page.Description}</p>");
                node.AppendChild(descNode);
            }

            if (!string.IsNullOrWhiteSpace(bodyHtml))
                node.InnerHtml += bodyHtml;

            return node;
        }
    }
}
