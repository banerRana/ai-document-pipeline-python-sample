#!/usr/bin/env bash

###############################################################################
# Usage:
#   ./deploy_infrastructure.sh <deploymentName> <location> [--what-if]
################################################################################

set -eu

# Setup STDERR.
err() {
    echo "(!) $*" >&2
}

# Validate arguments
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <deploymentName> <location> [--what-if]" >&2
  exit 1
fi

DEPLOYMENT_NAME="$1"
LOCATION="$2"
WHAT_IF=false

# Check for --what-if in arguments
if [ "$#" -eq 3 ] && [ "$3" = "--what-if" ]; then
    WHAT_IF=true
fi

echo "Starting infrastructure deployment..."

# Ensure the working directory is the script's location
cd "$(dirname "$0")"

# Get the Azure AD principal ID of the authenticated user for the deployment
PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)
IDENTITY_ARRAY=$(jq -c -n --arg pid "$PRINCIPAL_ID" '[ { "principalId": $pid, "principalType": "User" } ]')

# If --what-if is specified, preview the deployment
if [ "$WHAT_IF" = true ]; then
    echo "Previewing infrastructure deployment. No changes will be made." >&2

    set +e
    WHAT_IF_RESULT=$(az deployment sub what-if \
        --name "$DEPLOYMENT_NAME" \
        --location "$LOCATION" \
        --template-file '../core.bicep' \
        --parameters '../core.bicepparam' \
        --parameters workloadName="$DEPLOYMENT_NAME" \
        --parameters location="$LOCATION" \
        --parameters identities="$IDENTITY_ARRAY" \
        --no-pretty-print 2>/dev/null)
    EXIT_CODE=$?
    set -e

    if [ $EXIT_CODE -ne 0 ] || [ -z "$WHAT_IF_RESULT" ]; then
        echo "Infrastructure deployment preview failed." >&2
        exit 1
    fi

    echo "Infrastructure deployment preview succeeded." >&2

    echo "$WHAT_IF_RESULT" | jq '.changes'
    exit 0
fi

# Deploy the infrastructure
DEPLOYMENT_OUTPUTS=$(az deployment sub create \
    --name "$DEPLOYMENT_NAME" \
    --location "$LOCATION" \
    --template-file '../core.bicep' \
    --parameters '../core.bicepparam' \
    --parameters workloadName="$DEPLOYMENT_NAME" \
    --parameters location="$LOCATION" \
    --parameters identities="$IDENTITY_ARRAY" \
    --query properties.outputs -o json)

# If the deployment outputs are empty, we consider this an error
if [ -z "$DEPLOYMENT_OUTPUTS" ]; then
    echo "Infrastructure deployment failed." >&2
    exit 1
fi

echo "Infrastructure deployment succeeded." >&2
echo "$DEPLOYMENT_OUTPUTS" | jq '.' > ./InfrastructureOutputs.json

exit 0
