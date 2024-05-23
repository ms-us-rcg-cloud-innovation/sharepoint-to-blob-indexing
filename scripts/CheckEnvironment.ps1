$MissingSomething = [bool]::Parse("false")

$greenCheck = @{
    Object = [Char]8730
    ForegroundColor = 'Green'
    NoNewLine = $true
    }

# Check if the needed components are installed
Write-Host "------------------------------------"
Write-Host "Checking Azure CLI"
try{ az --version }
catch
    { 
        Write-Error ">>>> Azure CLI not installed. Please install and try again." 
        $MissingSomething = [bool]::Parse("true")
    }
Write-Host ""

Write-Host "------------------------------------"
Write-Host "Checking Azure Developer CLI (azd)"
try{ 
    $azdVersion = azd version
    Write-Host @greenCheck
    write-host " - Azure Developer CLI version: $azdVersion"
}
catch
    { 
        Write-Error ">>>> Azure Developer CLI not installed. Please install and try again."  
        Write-Error ">>>> You can install it by running the following command in a terminal window: winget install microsoft.azd" 
        $MissingSomething = [bool]::Parse("true")
    }
Write-Host ""

Write-Host "------------------------------------"
Write-Host "Checking Azure Functions Core Tools"
try {
    $funcVersion = func --version
    Write-Host @greenCheck
    Write-Host " - Azure Functions Core Tools version: $funcVersion"
    }
catch 
    { 
        Write-Error ">>>> Azure Functions Core Tools not installed. Please install and try again." 
        Write-Error ">>>> You can install it by visiting https://learn.microsoft.com/en-us/azure/azure-functions/functions-run-local" 
        $MissingSomething = [bool]::Parse("true")
    }
Write-Host ""

if ($MissingSomething)
    {
        Write-Error "------------------------------------"
        Write-Error "One or more components are missing. "
        Write-Error "Please review the log above and install the missing components before continuing" 
    }
    else {
        Write-Host "------------------------------------"
        Write-Host "All dependent components installed!" -ForegroundColor green
        Write-Host "------------------------------------"
    }