using System;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using CreateAzureAIComponents.Models;

namespace CreateAzureAIComponents
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            var services = CreateServices();

            Application app = services.GetRequiredService<Application>();
            await app.CreateSearchObjects();
        }

        private static ServiceProvider CreateServices()
        {
            var configuration = new ConfigurationBuilder()
                .AddJsonFile("appsettings.json")
                .AddEnvironmentVariables()
                .Build();

            var serviceProvider = new ServiceCollection()
                 .AddLogging(options =>
                 {
                     options.ClearProviders();
                     options.AddConsole();
                 })
                 .AddScoped<IConfiguration>(_ => configuration)
                 .AddSingleton<Application>()
                 .AddHttpClient()
                 .AddOptions()
                 .Configure<OpenAIOptions>(configuration.GetSection("OpenAI"))
                 .Configure<AzureAISearchOptions>(configuration.GetSection("AISearch"))
                 .Configure<BlobOptions>(configuration.GetSection("BlobStorage"))
                 .BuildServiceProvider();

            return serviceProvider;
        }
    }
}
