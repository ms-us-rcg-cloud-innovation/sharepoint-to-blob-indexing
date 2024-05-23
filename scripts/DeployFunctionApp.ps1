param (
    [Parameter(Mandatory = $true)]
    [string]$FunctionAppName
)

az login

Set-Location ../src/Apps/SharepointToBlobFunctions

# create local.settings.json if it doesn't exist
if (-not (Test-Path "local.settings.json")) {
    # Create the JSON object
    $jsonObject = @{
        "IsEncrypted" = $false
        "Values" = @{
            "AzureWebJobsStorage" = ""
            "FUNCTIONS_WORKER_RUNTIME" = "dotnet-isolated"
        }
    }

    $jsonString = $jsonObject | ConvertTo-Json -Depth 4
    $jsonString | Out-File "local.settings.json" -Encoding UTF8
}

func azure functionapp publish $FunctionAppName
if ($? -eq $false) {
    Write-Error "Error publishing function app."
    exit 1 
}

Set-Location ../../../scripts/

