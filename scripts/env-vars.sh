#!/bin/bash

# Environment Variables Helper Script
# Usage: source ./scripts/env-vars.sh <environment>

ENVIRONMENT=${1:-dev}

case $ENVIRONMENT in
  dev)
    export RESOURCE_GROUP_NAME="walletwatch-dev-rg"
    export ACR_NAME="walletwatchdevacr"
    export LOCATION="East US"
    export ACR_SKU="Basic"
    ;;
  staging)
    export RESOURCE_GROUP_NAME="walletwatch-stg-rg"
    export ACR_NAME="walletwatchstgacr"
    export LOCATION="East US"
    export ACR_SKU="Standard"
    ;;
  prod)
    export RESOURCE_GROUP_NAME="walletwatch-prod-rg"
    export ACR_NAME="walletwatchprodacr"
    export LOCATION="East US"
    export ACR_SKU="Premium"
    ;;
  *)
    echo "Unknown environment: $ENVIRONMENT"
    exit 1
    ;;
esac

echo "Environment variables set for: $ENVIRONMENT"
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "ACR Name: $ACR_NAME"