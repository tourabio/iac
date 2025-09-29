# Staging Environment Setup Guide

This guide provides step-by-step instructions to set up the staging environment for the WalletWatch infrastructure.

## Overview

**Environment**: Staging
**Location**: France Central
**Resource Groups**:
- `walletwatch-staging-persistent-rg` (contains identities only)
- `walletwatch-staging-rg` (contains all Terraform-managed resources)

## Prerequisites

- Azure CLI installed and authenticated
- Appropriate permissions to create resource groups and managed identities
- Access to admin for role assignments

## Step 1: Create Resource Groups

### 1.1 Create Persistent Resource Group
```bash
az group create \
  --name "walletwatch-staging-persistent-rg" \
  --location "France Central" \
  --tags environment=staging project=walletwatch managed_by=manual
```

### 1.2 Create Main Resource Group
```bash
az group create \
  --name "walletwatch-staging-rg" \
  --location "France Central" \
  --tags environment=staging project=walletwatch managed_by=terraform
```

## Step 2: Create Managed Identities

### 2.1 Create Kubelet Identity
```bash
az identity create \
  --name "walletwatch-staging-aks-kubelet-identity" \
  --resource-group "walletwatch-staging-persistent-rg" \
  --location "France Central" \
  --tags environment=staging project=walletwatch purpose=aks-kubelet
```

### 2.2 Create Control Plane Identity
```bash
az identity create \
  --name "walletwatch-staging-aks-controlplane-identity" \
  --resource-group "walletwatch-staging-persistent-rg" \
  --location "France Central" \
  --tags environment=staging project=walletwatch purpose=aks-controlplane
```

## Step 3: Collect Identity Information

### 3.1 Get Kubelet Identity Details
```bash
# Get principal ID (for role assignments)
az identity show \
  --name "walletwatch-staging-aks-kubelet-identity" \
  --resource-group "walletwatch-staging-persistent-rg" \
  --query principalId \
  --output tsv

# Get client ID (for AKS configuration)
az identity show \
  --name "walletwatch-staging-aks-kubelet-identity" \
  --resource-group "walletwatch-staging-persistent-rg" \
  --query clientId \
  --output tsv

# Get resource ID (for control plane role assignment scope)
az identity show \
  --name "walletwatch-staging-aks-kubelet-identity" \
  --resource-group "walletwatch-staging-persistent-rg" \
  --query id \
  --output tsv
```

### 3.2 Get Control Plane Identity Details
```bash
# Get principal ID (for role assignments)
az identity show \
  --name "walletwatch-staging-aks-controlplane-identity" \
  --resource-group "walletwatch-staging-persistent-rg" \
  --query principalId \
  --output tsv
```

### 3.3 Get Your User Principal ID
```bash
# Get your user principal ID (for Key Vault access)
az ad signed-in-user show --query id --output tsv
```

### 3.4 Get Service Principal ID
```bash
# Get service principal ID used for GitHub Actions
# Replace with your actual service principal ID
echo "SERVICE_PRINCIPAL_ID"
```

## Step 4: Admin Role Assignment Commands

**📋 Copy these commands and send to your admin for execution:**

Replace the placeholders with the actual values collected in Step 3:

```bash
# ==================================================================
# STAGING ENVIRONMENT ROLE ASSIGNMENTS
# Replace <values> with actual IDs from Step 3 above
# ==================================================================

# 1. Control Plane Identity → Kubelet Identity (Managed Identity Operator)
az role assignment create \
  --assignee <controlplane-identity-principal-id> \
  --role "Managed Identity Operator" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-staging-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/walletwatch-staging-aks-kubelet-identity"

# 2. Kubelet Identity → Resource Group (AcrPull)
az role assignment create \
  --assignee <kubelet-identity-principal-id> \
  --role "AcrPull" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-staging-rg"

# 3. Kubelet Identity → Resource Group (Key Vault Secrets User)
az role assignment create \
  --assignee <kubelet-identity-principal-id> \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-staging-rg"

# 4. Service Principal → Resource Group (Key Vault Secrets Officer)
az role assignment create \
  --assignee SERVICE_PRINCIPAL_ID \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-staging-rg"

# 5. User → Resource Group (Key Vault Secrets Officer)
az role assignment create \
  --assignee <your-user-principal-id> \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-staging-rg"

# 6. Control Plane Identity → Resource Group (Network Contributor)
az role assignment create \
  --assignee <controlplane-identity-principal-id> \
  --role "Network Contributor" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-staging-rg"

# 7. Kubelet Identity → Resource Group (Key Vault Crypto User) - for JWT signing operations
az role assignment create \
  --assignee <kubelet-identity-principal-id> \
  --role "Key Vault Crypto User" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-staging-rg"

# 8. Service Principal → Resource Group (Key Vault Crypto Officer) - for JWT key management via Terraform
az role assignment create \
  --assignee SERVICE_PRINCIPAL_ID \
  --role "Key Vault Crypto Officer" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-staging-rg"

# 9. User → Resource Group (Key Vault Crypto User) - for JWT key debugging and management
az role assignment create \
  --assignee <your-user-principal-id> \
  --role "Key Vault Crypto User" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-staging-rg"
```

## Step 5: Verification Commands

After admin completes role assignments, verify setup:

### 5.1 Verify Resource Groups
```bash
az group list --query "[?contains(name, 'walletwatch-staging')].{Name:name, Location:location, ProvisioningState:properties.provisioningState}" --output table
```

### 5.2 Verify Managed Identities
```bash
az identity list --resource-group "walletwatch-staging-persistent-rg" --output table
```

### 5.3 Verify Role Assignments
```bash
# Check kubelet identity role assignments
az role assignment list \
  --assignee <kubelet-identity-principal-id> \
  --output table

# Check control plane identity role assignments
az role assignment list \
  --assignee <controlplane-identity-principal-id> \
  --output table
```

## Step 6: Environment Configuration

The staging environment is configured with:

**Infrastructure Sizing (Cost-Balanced):**
- **ACR**: Standard tier for testing container workflows
- **Key Vault**: Standard tier with RBAC authorization
- **AKS**: Auto-scaling 1-2 nodes, Standard_B2s VMs
- **PostgreSQL**: Basic tier B_Standard_B2s (2 vCore, 4GB RAM)

**Security Settings:**
- Network access: Allow all (for development ease)
- Backup retention: 14 days
- Soft delete retention: 14 days
- Purge protection: Disabled

## Step 7: Deploy Infrastructure

After setup is complete, deploy infrastructure using GitHub Actions:

1. **Manual Deployment**:
   - Go to GitHub Actions
   - Run "Create Infrastructure" workflow
   - Select "staging" environment
   - Approve in `staging-approval` environment

2. **Direct Terraform**:
```bash
cd infrastructure/
terraform init
terraform plan -var-file="environments/staging/terraform.tfvars" -var="subscription_id=SUBSCRIPTION_ID"
terraform apply -var-file="environments/staging/terraform.tfvars" -var="subscription_id=SUBSCRIPTION_ID"
```

## Cleanup (Cost Savings)

Staging environment has scheduled cleanup at 20:00 UTC to save costs:

**Manual Cleanup**:
```bash
terraform destroy -var-file="environments/staging/terraform.tfvars" -var="subscription_id=SUBSCRIPTION_ID"
```

**Note**: Identities and role assignments persist after cleanup - only Terraform-managed resources are destroyed.

## Troubleshooting

### Common Issues:

1. **Identity Not Found**:
   - Verify identities exist in persistent resource group
   - Check spelling of identity names

2. **Role Assignment Failures**:
   - Ensure admin has sufficient permissions
   - Verify principal IDs are correct (not client IDs)
   - Check subscription ID and resource group names

3. **Terraform Failures**:
   - Verify role assignments are complete
   - Check that persistent_resource_group_name variable matches actual RG name
   - Ensure identities exist before running terraform

### Support Commands:

```bash
# List all staging resources
az resource list --resource-group "walletwatch-staging-rg" --output table
az resource list --resource-group "walletwatch-staging-persistent-rg" --output table

# Check subscription and tenant
az account show --query "{SubscriptionId:id, TenantId:tenantId, Name:name}" --output table
```

---

**Next Steps**: After staging setup is complete, proceed with production environment setup using `prod.md`.