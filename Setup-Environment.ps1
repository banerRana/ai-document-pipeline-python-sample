param
(
    [Parameter(Mandatory = $true)]
    [string]$DeploymentName,
    [Parameter(Mandatory = $true)]
    [string]$Location,
    [switch]$IsLocal,
    [switch]$WhatIf
)

Write-Host "Starting environment setup..."

Write-Host "Deploying infrastructure..."
$InfrastructureOutputs = (./infra/scripts/Deploy-Infrastructure.ps1 `
        -DeploymentName $DeploymentName `
        -Location $Location `
        -WhatIf:$WhatIf)

if ($WhatIf) {
    Write-Host "WhatIf mode is enabled. Exiting without deploying."
    exit 0
}

if (-not $InfrastructureOutputs) {
    Write-Error "Failed to deploy infrastructure."
    exit 1
}

$AzureAIServicesEndpoint = $InfrastructureOutputs.environmentInfo.value.azureAIServicesEndpoint
$AzureOpenAIEndpoint = $InfrastructureOutputs.environmentInfo.value.azureOpenAIEndpoint
$AzureOpenAIChatDeployment = $InfrastructureOutputs.environmentInfo.value.azureOpenAIChatDeployment
$AzureStorageAccount = $InfrastructureOutputs.environmentInfo.value.azureStorageAccount

Write-Host "Updating ./src/AIDocumentPipeline/local.settings.json..."

$LocalSettingsPath = './src/AIDocumentPipeline/local.settings.json'
$LocalSettings = Get-Content -Path $LocalSettingsPath -Raw | ConvertFrom-Json
$LocalSettings.Values.AZURE_AISERVICES_ENDPOINT = $AzureAIServicesEndpoint
$LocalSettings.Values.AZURE_OPENAI_ENDPOINT = $AzureOpenAIEndpoint
$LocalSettings.Values.AZURE_OPENAI_CHAT_DEPLOYMENT = $AzureOpenAIChatDeployment
$LocalSettings.Values.AZURE_STORAGE_ACCOUNT = $AzureStorageAccount
$LocalSettings | ConvertTo-Json | Out-File -FilePath $LocalSettingsPath -Encoding utf8

if ($IsLocal) {
    Write-Host "Starting local environment..."

    docker-compose up
}
else {
    Write-Host "Deploying AI Document Pipeline app to Azure..."

    $AppOutputs = (./infra/scripts/Deploy-App.ps1 `
            -InfrastructureOutputsPath './infra/scripts/InfrastructureOutputs.json')
}
