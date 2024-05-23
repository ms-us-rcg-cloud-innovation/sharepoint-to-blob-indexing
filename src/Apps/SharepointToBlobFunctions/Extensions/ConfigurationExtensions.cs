using Microsoft.Extensions.Configuration;

namespace SharepointToBlobFunctions
{
    internal static class ConfigurationExtensions
    {
        public static string GetRequiredValue(this IConfiguration configuration, string key)
        {
            string? value = configuration.GetValue<string>(key);
            if (string.IsNullOrWhiteSpace(value))
                throw new InvalidOperationException($"Missing config {key}");

            return value;
        }
    }
}
