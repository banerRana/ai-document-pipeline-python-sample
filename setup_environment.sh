#!/usr/bin/env bash

###############################################################################
# Usage:
#   ./setup_environment.sh <deploymentName> <location> [--is-local]
################################################################################

set -eu

# Setup STDERR.
err() {
    echo "(!) $*" >&2
}

# Validate arguments
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <deploymentName> <location> [--is-local]" >&2
  exit 1
fi

DEPLOYMENT_NAME="$1"
LOCATION="$2"
IS_LOCAL=false

# Check for --is-local in arguments
if [ "$#" -eq 3 ] && [ "$3" = "--is-local" ]; then
    IS_LOCAL=true
fi

echo "Starting environment setup..."

echo "Deploying infrastructure..."
INFRASTRUCTURE_OUTPUTS=$(bash ./infra/scripts/deploy_infrastructure.sh \
    "$DEPLOYMENT_NAME" \
    "$LOCATION")

if [ -z "$INFRASTRUCTURE_OUTPUTS" ]; then
    echo "Failed to deploy infrastructure." >&2
    exit 1
fi

AZURE_AI_SERVICES_ENDPOINT=$(echo "$INFRASTRUCTURE_OUTPUTS" | jq -r '.environmentInfo.value.azureAIServicesEndpoint')
AZURE_OPENAI_ENDPOINT=$(echo "$INFRASTRUCTURE_OUTPUTS" | jq -r '.environmentInfo.value.azureOpenAIEndpoint')
AZURE_OPENAI_CHAT_DEPLOYMENT=$(echo "$INFRASTRUCTURE_OUTPUTS" | jq -r '.environmentInfo.value.azureOpenAIChatDeployment')
AZURE_STORAGE_ACCOUNT=$(echo "$INFRASTRUCTURE_OUTPUTS" | jq -r '.environmentInfo.value.azureStorageAccount')

echo "Updating ./src/AIDocumentPipeline/local.settings.json..."

jq --arg endpoint "$AZURE_AI_SERVICES_ENDPOINT" \
   --arg openai_endpoint "$AZURE_OPENAI_ENDPOINT" \
   --arg openai_deployment "$AZURE_OPENAI_CHAT_DEPLOYMENT" \
   --arg storage_account "$AZURE_STORAGE_ACCOUNT" \
   '.Values.AZURE_AISERVICES_ENDPOINT = $endpoint |
    .Values.AZURE_OPENAI_ENDPOINT = $openai_endpoint |
    .Values.AZURE_OPENAI_CHAT_DEPLOYMENT = $openai_deployment |
    .Values.AZURE_STORAGE_ACCOUNT = $storage_account' \
   ./src/AIDocumentPipeline/local.settings.json > ./src/AIDocumentPipeline/local.settings.json.tmp

mv ./src/AIDocumentPipeline/local.settings.json.tmp ./src/AIDocumentPipeline/local.settings.json

if [ "$IS_LOCAL" = true ]; then
    echo "Starting local environment..."

    docker-compose up
else
    echo "Deploying AI Document Pipeline app to Azure..."

    bash ./infra/scripts/deploy_app.sh ./infra/scripts/InfrastructureOutputs.json
fi
