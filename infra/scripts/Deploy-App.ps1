param
(
    [Parameter(Mandatory = $true)]
    [string]$InfrastructureOutputsPath
)

$InfrastructureOutputs = Get-Content -Path $InfrastructureOutputsPath -Raw | ConvertFrom-Json

$AzureResourceGroup = $InfrastructureOutputs.environmentInfo.value.azureResourceGroup
$ContainerRegistryName = $InfrastructureOutputs.environmentInfo.value.containerRegistryName
$ContainerName = $InfrastructureOutputs.environmentInfo.value.applicationName
$ContainerAppName = $InfrastructureOutputs.environmentInfo.value.applicationContainerAppName

$ContainerVersion = (Get-Date -Format "yyMMddHHmm")
$ContainerImageName = "${ContainerName}:${ContainerVersion}"
$AzureContainerImageName = "${ContainerRegistryName}.azurecr.io/${ContainerImageName}"

Push-Location -Path $PSScriptRoot

Write-Host "Starting ${ContainerName} deployment..."

az --version

Write-Host "Building ${ContainerImageName} image..."

az acr login --name $ContainerRegistryName --resource-group $AzureResourceGroup

docker build -t $ContainerImageName -f ../../src/AIDocumentPipeline/Dockerfile ../../src/AIDocumentPipeline/.

Write-Host "Pushing ${ContainerImageName} image to Azure..."

docker tag $ContainerImageName $AzureContainerImageName
docker push $AzureContainerImageName

Write-Host "Deploying Azure Container Apps for ${ContainerName}..."

$acrLogin = $(az acr show --name $ContainerRegistryName --resource-group $AzureResourceGroup -o json | ConvertFrom-Json).loginServer

az containerapp update --name $ContainerAppName --resource-group $AzureResourceGroup --image "$acrLogin/$ContainerImageName"

Write-Host "Cleaning up old ${ContainerName} images in Azure Container Registry..."

az acr run --cmd "acr purge --filter '${ContainerName}:.*' --untagged --ago 1h" --registry $ContainerRegistryName --resource-group $AzureResourceGroup /dev/null

Pop-Location
