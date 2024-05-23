$logicAppName = $env:AZURE_LOGIC_APP_NAME
$resourceGroupName = $env:AZURE_RESOURCE_GROUP_NAME

$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$root = Resolve-Path "$dir/../"

Push-Location $root

New-Item -Force -Path "output" -ItemType "directory"

Write-Host "- Setting up Logic App"

Compress-Archive -Path .\src\LogicApps\* -DestinationPath .\output\workflows.zip -Force

az logicapp deployment source config-zip --name $logicAppName  --resource-group $resourceGroupName --src .\output\workflows.zip
Write-Host "- Logic App Setup Complete for $logicAppName in $resourceGroupName."

Pop-Location