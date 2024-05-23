using Microsoft.Graph.Models;

namespace SharepointToBlobFunctions
{
    public interface IStandardWebPartHtmlHandler
    {
        string Title { get; }
        Task<string> GetHtmlAsync(StandardWebPart webPart);
    }
}
