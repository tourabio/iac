#!/bin/bash

# WalletWatch Resource Discovery Script
# Usage: ./scripts/check-resources.sh <environment> <subscription_id>

set -e

ENVIRONMENT=${1:-dev}
SUBSCRIPTION_ID=${2}

# Validate inputs
if [[ -z "$SUBSCRIPTION_ID" ]]; then
    echo "❌ Error: Subscription ID is required"
    echo "Usage: $0 <environment> <subscription_id>"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Error: Environment must be dev, staging, or prod"
    exit 1
fi

echo "🔍 Checking WalletWatch Resources in Azure"
echo "Environment: $ENVIRONMENT"
echo "Subscription: $SUBSCRIPTION_ID"

# Set subscription
az account set --subscription $SUBSCRIPTION_ID

# Expected resource names based on environment
if [ "$ENVIRONMENT" == "dev" ]; then
    RG_NAME="walletwatch-dev-rg"
    ACR_NAME="walletwatchdevacr"
elif [ "$ENVIRONMENT" == "staging" ]; then
    RG_NAME="walletwatch-staging-rg"
    ACR_NAME="walletwatchstagingacr"
elif [ "$ENVIRONMENT" == "prod" ]; then
    RG_NAME="walletwatch-prod-rg"
    ACR_NAME="walletwatchprodacr"
fi

echo ""
echo "🔍 Looking for Resource Group: $RG_NAME"
RG_EXISTS=$(az group exists --name $RG_NAME)
if [ "$RG_EXISTS" == "true" ]; then
    echo "✅ Resource Group found: $RG_NAME"
    echo "📊 Resource Group details:"
    az group show --name $RG_NAME --query "{Name:name, Location:location, ProvisioningState:properties.provisioningState}" -o table
    
    echo ""
    echo "🔍 Resources in the group:"
    az resource list --resource-group $RG_NAME --query "[].{Name:name, Type:type, Location:location}" -o table
else
    echo "❌ Resource Group not found: $RG_NAME"
fi

echo ""
echo "🔍 Looking for ACR: $ACR_NAME"
ACR_EXISTS=$(az acr show --name $ACR_NAME --query "name" -o tsv 2>/dev/null || echo "")
if [ -n "$ACR_EXISTS" ]; then
    echo "✅ ACR found: $ACR_NAME"
    echo "📊 ACR details:"
    az acr show --name $ACR_NAME --query "{Name:name, ResourceGroup:resourceGroup, LoginServer:loginServer, Sku:sku.name, ProvisioningState:provisioningState}" -o table
else
    echo "❌ ACR not found: $ACR_NAME"
fi

echo ""
echo "📋 Summary:"
if [ "$RG_EXISTS" == "true" ] || [ -n "$ACR_EXISTS" ]; then
    echo "✅ Resources found in Azure that need to be imported into Terraform state"
    echo ""
    echo "🔧 To import these resources, run:"
    if [ "$RG_EXISTS" == "true" ]; then
        echo "terraform import module.resource_group.azurerm_resource_group.default /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME"
    fi
    if [ -n "$ACR_EXISTS" ]; then
        echo "terraform import module.acr.azurerm_container_registry.acr /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME"
    fi
else
    echo "ℹ️ No resources found in Azure for environment: $ENVIRONMENT"
fi