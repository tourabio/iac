#!/bin/bash

# WalletWatch Infrastructure Deployment Script
# Usage: ./scripts/deploy.sh <environment> <subscription_id>

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

echo "🚀 Deploying WalletWatch Infrastructure"
echo "Environment: $ENVIRONMENT"
echo "Subscription: $SUBSCRIPTION_ID"

# Navigate to infrastructure directory
cd "$(dirname "$0")/../infrastructure"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning deployment..."
terraform plan \
  -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
  -var="subscription_id=$SUBSCRIPTION_ID" \
  -out="tfplan"

# Confirm deployment
read -p "Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Applying changes..."
    terraform apply tfplan
    
    echo "✅ Deployment completed successfully!"
    echo "📊 Infrastructure outputs:"
    terraform output
else
    echo "⏹️ Deployment cancelled"
    rm -f tfplan
fi