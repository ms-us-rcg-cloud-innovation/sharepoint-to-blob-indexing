using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using SharepointToBlobFunctions;

namespace SharepointToBlob
{
    public class SharepointPagesQueueFunction
    {
        private readonly ILogger<SharepointPagesQueueFunction> _logger;
        private readonly SharepointPageProcessor _processor;

        public SharepointPagesQueueFunction(
            SharepointPageProcessor processor,
            ILogger<SharepointPagesQueueFunction> logger)
        {
            _logger = logger;
            _processor = processor;
        }

        [Function(nameof(SharepointPagesQueueFunction))]
        public async Task Run([QueueTrigger("sharepoint-pages")] PageUpdatedQueueMessage message)
        {
            try
            {
                if (message is null)
                    throw new ArgumentNullException(nameof(message));

                await _processor.ProcessAsync(message.ToContext()); ;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, ex.Message);
            }
        }
    }
}