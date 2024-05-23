using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace CreateAzureAIComponents.Models
{
    public class AzureAISearchOptions
    {
        public string? ServiceName { get; set; }
        public string? Endpoint { get; set; }
        public string? Key { get; set; }
        public string? AdminKey { get; set; }
        public string? SkillsetName { get; set; }
        public string? IndexName { get; set; }
        public string? IndexerName { get; set; }
    }
}
