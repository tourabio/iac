#!/bin/bash

# Setup Azure Backend for Terraform State
# This script creates the required Azure resources for storing Terraform state

set -e

RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="tfstatewalletwatch"
CONTAINER_NAME="tfstate"
LOCATION="East US"

echo "🚀 Setting up Azure Backend for Terraform State..."

# Check if Azure CLI is logged in
if ! az account show >/dev/null 2>&1; then
    echo "❌ Please login to Azure CLI first: az login"
    exit 1
fi

# Create resource group
echo "📦 Creating resource group: $RESOURCE_GROUP_NAME"
az group create \
    --name "$RESOURCE_GROUP_NAME" \
    --location "$LOCATION" \
    --tags purpose="terraform-state" project="walletwatch"

# Create storage account
echo "💾 Creating storage account: $STORAGE_ACCOUNT_NAME"
az storage account create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$STORAGE_ACCOUNT_NAME" \
    --sku Standard_LRS \
    --encryption-services blob \
    --https-only true \
    --min-tls-version TLS1_2 \
    --allow-blob-public-access false \
    --tags purpose="terraform-state" project="walletwatch"

# Create storage container
echo "🗂️ Creating storage container: $CONTAINER_NAME"
az storage container create \
    --name "$CONTAINER_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --auth-mode login

# Enable versioning for the storage account
echo "🔄 Enabling blob versioning..."
az storage account blob-service-properties update \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --enable-versioning true

echo "✅ Azure Backend setup complete!"
echo ""
echo "📋 Backend Configuration:"
echo "  Resource Group: $RESOURCE_GROUP_NAME"
echo "  Storage Account: $STORAGE_ACCOUNT_NAME"
echo "  Container: $CONTAINER_NAME"
echo ""

# Get storage account access key
echo "🔑 Getting Storage Account Access Key..."
ACCESS_KEY=$(az storage account keys list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --account-name "$STORAGE_ACCOUNT_NAME" \
    --query '[0].value' \
    --output tsv)

echo "🔑 Required GitHub Secrets:"
echo "  ARM_CLIENT_ID=<your-service-principal-app-id>"
echo "  ARM_CLIENT_SECRET=<your-service-principal-secret>"
echo "  ARM_TENANT_ID=<your-tenant-id>"
echo "  ARM_SUBSCRIPTION_ID=<your-subscription-id>"
echo "  ARM_ACCESS_KEY=$ACCESS_KEY"
echo ""
echo "📋 Copy the ARM_ACCESS_KEY value above to your GitHub Secrets!"
echo ""
echo "🚀 Next steps:"
echo "1. Add ARM_ACCESS_KEY to your GitHub repository secrets"
echo "2. Run 'terraform init' to initialize the backend"
echo "3. Deploy your infrastructure"
echo "4. State will now be stored in Azure and shared across all environments"