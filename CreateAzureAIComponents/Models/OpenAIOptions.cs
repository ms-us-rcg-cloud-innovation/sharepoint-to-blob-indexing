using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CreateAzureAIComponents.Models
{
    public class OpenAIOptions
    {
        public string Endpoint { get; set; }
        public string Key { get; set; }
        public string EmbeddingsDeployment { get; set; }
        public string CompletionsDeployment { get; set; }
    }
}
