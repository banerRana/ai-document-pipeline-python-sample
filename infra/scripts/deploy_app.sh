#!/usr/bin/env bash

###############################################################################
# Usage:
#   ./deploy_app.sh <infrastructureOutputsPath>
################################################################################

set -eu

# Setup STDERR.
err() {
    echo "(!) $*" >&2
}

# Validate arguments
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <infrastructureOutputsPath>" >&2
  exit 1
fi

INFRASTRUCTURE_OUTPUTS_PATH="$1"

INFRASTRUCTURE_OUTPUTS=$(cat "$INFRASTRUCTURE_OUTPUTS_PATH")
AZURE_RESOURCE_GROUP=$(echo "$INFRASTRUCTURE_OUTPUTS" | jq -r '.environmentInfo.value.azureResourceGroup')
CONTAINER_REGISTRY_NAME=$(echo "$INFRASTRUCTURE_OUTPUTS" | jq -r '.environmentInfo.value.containerRegistryName')
CONTAINER_NAME=$(echo "$INFRASTRUCTURE_OUTPUTS" | jq -r '.environmentInfo.value.applicationName')
CONTAINER_APP_NAME=$(echo "$INFRASTRUCTURE_OUTPUTS" | jq -r '.environmentInfo.value.applicationContainerAppName')

CONTAINER_VERSION=$(date +%y%m%d%H%M)
CONTAINER_IMAGE_NAME="$CONTAINER_NAME:$CONTAINER_VERSION"
AZURE_CONTAINER_IMAGE_NAME="$CONTAINER_REGISTRY_NAME.azurecr.io/$CONTAINER_IMAGE_NAME"

# Ensure the working directory is the script's location
cd "$(dirname "$0")"

echo "Starting $CONTAINER_NAME deployment..."

echo "Building $CONTAINER_IMAGE_NAME image..."

az acr login \
    --name $CONTAINER_REGISTRY_NAME \
    --resource-group $AZURE_RESOURCE_GROUP

docker build \
    -t $CONTAINER_IMAGE_NAME \
    -f ../../src/AIDocumentPipeline/Dockerfile \
    ../../src/AIDocumentPipeline/.

echo "Pushing $CONTAINER_IMAGE_NAME image to Azure..."

docker tag $CONTAINER_IMAGE_NAME $AZURE_CONTAINER_IMAGE_NAME
docker push $AZURE_CONTAINER_IMAGE_NAME

echo "Deploying Azure Container Apps for $CONTAINER_NAME..."

ACR_LOGIN=$(az acr show --name $CONTAINER_REGISTRY_NAME --resource-group $AZURE_RESOURCE_GROUP --query loginServer -o tsv)

az containerapp update \
    --name $CONTAINER_APP_NAME \
    --resource-group $AZURE_RESOURCE_GROUP \
    --image $ACR_LOGIN/$CONTAINER_IMAGE_NAME \
    --revision-suffix $CONTAINER_VERSION

if [ $? -ne 0 ]; then
    err "$CONTAINER_NAME deployment failed." >&2
    exit 1
fi

echo "$CONTAINER_NAME deployment succeeded." >&2
