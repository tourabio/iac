#!/bin/bash

# WalletWatch Infrastructure Destruction Script
# Usage: ./scripts/destroy.sh <environment> <subscription_id>

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

echo "🗑️ Destroying WalletWatch Infrastructure"
echo "Environment: $ENVIRONMENT"
echo "Subscription: $SUBSCRIPTION_ID"

# Navigate to infrastructure directory
cd "$(dirname "$0")/../infrastructure"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan destruction
echo "📋 Planning destruction..."
terraform plan -destroy \
  -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
  -var="subscription_id=$SUBSCRIPTION_ID"

# Double confirmation for destruction
echo "⚠️  WARNING: This will destroy all resources in the $ENVIRONMENT environment!"
read -p "Type 'destroy' to confirm: " -r
echo
if [[ $REPLY == "destroy" ]]; then
    echo "🗑️ Destroying infrastructure..."
    terraform destroy -auto-approve \
      -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
      -var="subscription_id=$SUBSCRIPTION_ID"
    
    echo "✅ Infrastructure destroyed successfully!"
else
    echo "⏹️ Destruction cancelled"
fi