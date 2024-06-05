using Azure.Identity;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Graph;
using SharepointToBlobFunctions;

var host = new HostBuilder()
    .ConfigureFunctionsWebApplication()
    //.ConfigureLogging(logging =>
    //{
    
    //    logging.AddFilter("Microsoft", LogLevel.Warning)
    //           .AddFilter("System", LogLevel.Warning)
    //           .AddFilter("SharepointToBlobFunctions", LogLevel.Information);
    //})
    .ConfigureServices(services => {
        services.AddApplicationInsightsTelemetryWorkerService();
        services.ConfigureFunctionsApplicationInsights();

        services.AddScoped<GraphServiceClient>(serviceProvider =>
        {
            var configuration = serviceProvider.GetRequiredService<IConfiguration>();

            string tenantId = configuration.GetRequiredValue("AZURE_SHAREPOINT_GRAPH_TENANT_ID");
            string clientId = configuration.GetRequiredValue("AZURE_SHAREPOINT_GRAPH_CLIENT_ID");
            string clientSecret = configuration.GetRequiredValue("AZURE_SHAREPOINT_GRAPH_CLIENT_SECRET");

            return new GraphServiceClient(
                new ClientSecretCredential(tenantId, clientId, clientSecret),
                ["https://graph.microsoft.com/.default"]);
        });

        services.AddScoped<BlobServiceClient>(serviceProvider =>
        {
            var configuration = serviceProvider.GetRequiredService<IConfiguration>();
            var connString = configuration.GetRequiredValue("AzureWebJobsStorage");
            return new BlobServiceClient(connString);
        });

        services.AddScoped<BlobContainerClient>(serviceProvider =>
        {
            var configuration = serviceProvider.GetRequiredService<IConfiguration>();
            var containerName = configuration.GetRequiredValue("AZURE_STORAGE_CONTAINER_NAME");
            var blobServiceClient = serviceProvider.GetRequiredService<BlobServiceClient>();
            return blobServiceClient.GetBlobContainerClient(containerName);
        });

        services.AddSingleton<IStandardWebPartHtmlHandler, ImageWebPartHtmlHandler>();

        services.AddSingleton<IReadOnlyDictionary<string, IStandardWebPartHtmlHandler>>(serviceProvider =>
        {
            return serviceProvider.GetServices<IStandardWebPartHtmlHandler>()?
                                  .ToDictionary(h => h.Title) ?? new Dictionary<string, IStandardWebPartHtmlHandler>();
        });

        services.AddSingleton<WebPartsHtmlBuilder>();
        services.AddScoped<SharepointPageProcessor>();
    })
    .Build();

host.Run();
