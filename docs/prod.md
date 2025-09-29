# Production Environment Setup Guide

This guide provides step-by-step instructions to set up the production environment for the WalletWatch infrastructure.

## Overview

**Environment**: Production
**Location**: France Central
**Resource Groups**:
- `walletwatch-prod-persistent-rg` (contains identities only)
- `walletwatch-prod-rg` (contains all Terraform-managed resources)

## Prerequisites

- Azure CLI installed and authenticated
- Appropriate permissions to create resource groups and managed identities
- Access to admin for role assignments
- **Production approval process** in place

## Step 1: Create Resource Groups

### 1.1 Create Persistent Resource Group
```bash
az group create \
  --name "walletwatch-prod-persistent-rg" \
  --location "France Central" \
  --tags environment=production project=walletwatch managed_by=manual
```

### 1.2 Create Main Resource Group
```bash
az group create \
  --name "walletwatch-prod-rg" \
  --location "France Central" \
  --tags environment=production project=walletwatch managed_by=terraform
```

## Step 2: Create Managed Identities

### 2.1 Create Kubelet Identity
```bash
az identity create \
  --name "walletwatch-prod-aks-kubelet-identity" \
  --resource-group "walletwatch-prod-persistent-rg" \
  --location "France Central" \
  --tags environment=production project=walletwatch purpose=aks-kubelet
```

### 2.2 Create Control Plane Identity
```bash
az identity create \
  --name "walletwatch-prod-aks-controlplane-identity" \
  --resource-group "walletwatch-prod-persistent-rg" \
  --location "France Central" \
  --tags environment=production project=walletwatch purpose=aks-controlplane
```

## Step 3: Collect Identity Information

### 3.1 Get Kubelet Identity Details
```bash
# Get principal ID (for role assignments)
az identity show \
  --name "walletwatch-prod-aks-kubelet-identity" \
  --resource-group "walletwatch-prod-persistent-rg" \
  --query principalId \
  --output tsv

# Get client ID (for AKS configuration)
az identity show \
  --name "walletwatch-prod-aks-kubelet-identity" \
  --resource-group "walletwatch-prod-persistent-rg" \
  --query clientId \
  --output tsv

# Get resource ID (for control plane role assignment scope)
az identity show \
  --name "walletwatch-prod-aks-kubelet-identity" \
  --resource-group "walletwatch-prod-persistent-rg" \
  --query id \
  --output tsv
```

### 3.2 Get Control Plane Identity Details
```bash
# Get principal ID (for role assignments)
az identity show \
  --name "walletwatch-prod-aks-controlplane-identity" \
  --resource-group "walletwatch-prod-persistent-rg" \
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
# PRODUCTION ENVIRONMENT ROLE ASSIGNMENTS
# Replace <values> with actual IDs from Step 3 above
# ==================================================================

# 1. Control Plane Identity → Kubelet Identity (Managed Identity Operator)
az role assignment create \
  --assignee <controlplane-identity-principal-id> \
  --role "Managed Identity Operator" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-prod-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/walletwatch-prod-aks-kubelet-identity"

# 2. Kubelet Identity → Resource Group (AcrPull)
az role assignment create \
  --assignee <kubelet-identity-principal-id> \
  --role "AcrPull" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-prod-rg"

# 3. Kubelet Identity → Resource Group (Key Vault Secrets User)
az role assignment create \
  --assignee <kubelet-identity-principal-id> \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-prod-rg"

# 4. Service Principal → Resource Group (Key Vault Secrets Officer)
az role assignment create \
  --assignee SERVICE_PRINCIPAL_ID \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-prod-rg"

# 5. User → Resource Group (Key Vault Secrets Officer)
az role assignment create \
  --assignee <your-user-principal-id> \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-prod-rg"

# 6. Control Plane Identity → Resource Group (Network Contributor)
az role assignment create \
  --assignee <controlplane-identity-principal-id> \
  --role "Network Contributor" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-prod-rg"
```

## Step 5: Verification Commands

After admin completes role assignments, verify setup:

### 5.1 Verify Resource Groups
```bash
az group list --query "[?contains(name, 'walletwatch-prod')].{Name:name, Location:location, ProvisioningState:properties.provisioningState}" --output table
```

### 5.2 Verify Managed Identities
```bash
az identity list --resource-group "walletwatch-prod-persistent-rg" --output table
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

## Step 6: Production Environment Configuration

The production environment is configured with **enhanced security and performance**:

### Infrastructure Sizing (Production-Ready)
- **ACR**: Premium tier with georeplications and network restrictions
- **Key Vault**: Premium tier with HSM support and enhanced security
- **AKS**: Auto-scaling 1-3 nodes, Standard_B2s VMs (scalable to larger sizes)
- **PostgreSQL**: Basic tier B_Standard_B2s (2 vCore, 4GB RAM) - upgradeable

### Security Settings (Enhanced)
- **Network Access**: Restricted by default (Deny) with specific IP allowlisting
- **Backup Retention**: 30 days (extended for production)
- **Soft Delete Retention**: 90 days (maximum)
- **Purge Protection**: Enabled (prevents accidental deletion)
- **Disk Encryption**: Enabled for Key Vault
- **RBAC Authorization**: Enabled for fine-grained access control

### Production-Specific Features
- **Georeplications**: Can be configured for ACR in multiple regions
- **Network ACLs**: IP-based restrictions for Key Vault access
- **Enhanced Monitoring**: Ready for Log Analytics integration
- **Compliance**: Settings aligned with enterprise security requirements

## Step 7: Production Security Review

**🔒 BEFORE DEPLOYING TO PRODUCTION:**

### 7.1 Security Checklist
- [ ] Network IP ranges defined for ACR access (if needed)
- [ ] Key Vault IP ranges defined for restricted access (if needed)
- [ ] Backup and disaster recovery plan documented
- [ ] Monitoring and alerting configured
- [ ] Change approval process in place

### 7.2 Update Network Restrictions (Optional)
If you need to restrict network access, update the terraform.tfvars:

```hcl
# Add your office/VPN IP ranges
acr_network_rule_ip_ranges = ["203.0.113.0/24", "198.51.100.0/24"]
keyvault_network_acls_ip_rules = ["203.0.113.0/24", "198.51.100.0/24"]
```

### 7.3 GitHub Environment Protection
Ensure `prod-approval` environment is configured with:
- Required reviewers (at least 2 people)
- Deployment protection rules
- Environment secrets properly configured

## Step 8: Deploy Production Infrastructure

**⚠️ PRODUCTION DEPLOYMENT REQUIRES MANUAL APPROVAL**

### 8.1 GitHub Actions Deployment (Recommended)
1. **Manual Deployment**:
   - Go to GitHub Actions
   - Run "Create Infrastructure" workflow
   - Select "prod" environment
   - **WAIT** for approval in `prod-approval` environment
   - Review deployment plan carefully before approving

### 8.2 Direct Terraform (Alternative)
```bash
cd infrastructure/

# Initialize and plan
terraform init
terraform plan \
  -var-file="environments/prod/terraform.tfvars" \
  -var="subscription_id=SUBSCRIPTION_ID" \
  -out=prod.tfplan

# Review plan thoroughly before applying
terraform show prod.tfplan

# Apply only after careful review
terraform apply prod.tfplan
```

## Step 9: Post-Deployment Validation

### 9.1 Verify Production Resources
```bash
# List all production resources
az resource list --resource-group "walletwatch-prod-rg" --output table

# Check AKS cluster status
az aks show --name "walletwatch-prod-aks" --resource-group "walletwatch-prod-rg" --query "provisioningState" --output tsv

# Verify ACR
az acr show --name "walletwatch-prod-acr" --resource-group "walletwatch-prod-rg" --query "{Name:name, Sku:sku.name, LoginServer:loginServer}" --output table

# Check Key Vault
az keyvault show --name "walletwatch-prod-kv" --resource-group "walletwatch-prod-rg" --query "{Name:name, Sku:properties.sku.name, VaultUri:properties.vaultUri}" --output table
```

### 9.2 Test Connectivity
```bash
# Get AKS credentials
az aks get-credentials --name "walletwatch-prod-aks" --resource-group "walletwatch-prod-rg" --overwrite-existing

# Test cluster connectivity
kubectl get nodes
kubectl get namespaces
```

## Step 10: Production Monitoring Setup

### 10.1 Enable Container Insights (Optional)
```bash
az aks enable-addons \
  --addons monitoring \
  --name "walletwatch-prod-aks" \
  --resource-group "walletwatch-prod-rg"
```

### 10.2 Set up Alerts
Configure monitoring alerts for:
- AKS cluster health
- ACR storage usage
- Key Vault access patterns
- PostgreSQL performance

## Production Maintenance

### Backup Verification
- **PostgreSQL**: Verify automated backups (30-day retention)
- **Key Vault**: Soft delete with 90-day retention
- **AKS**: Node pool configurations backed up in Terraform state

### Regular Tasks
- Monthly security updates
- Quarterly access review
- Cost optimization review
- Performance monitoring

### Emergency Procedures
```bash
# Emergency cluster stop (cost saving)
az aks stop --name "walletwatch-prod-aks" --resource-group "walletwatch-prod-rg"

# Emergency cluster start
az aks start --name "walletwatch-prod-aks" --resource-group "walletwatch-prod-rg"

# Scale down during maintenance
az aks scale --name "walletwatch-prod-aks" --resource-group "walletwatch-prod-rg" --node-count 1
```

## Troubleshooting

### Common Production Issues:

1. **Network Access Denied**:
   - Check IP allowlists in ACR/Key Vault network ACLs
   - Verify VPN/office IP ranges are correctly configured
   - Use Azure Cloud Shell if IP-restricted

2. **Key Vault Access Issues**:
   - Verify RBAC role assignments
   - Check soft delete state of secrets
   - Ensure purge protection settings

3. **AKS Scaling Issues**:
   - Check node pool configuration
   - Verify quota limits in subscription
   - Monitor resource utilization

### Production Support Commands:

```bash
# Check all production role assignments
az role assignment list --scope "/subscriptions/SUBSCRIPTION_ID/resourceGroups/walletwatch-prod-rg" --output table

# Verify network connectivity
az network public-ip list --resource-group "walletwatch-prod-rg" --output table

# Check Key Vault access policies
az keyvault show --name "walletwatch-prod-kv" --query "properties.enableRbacAuthorization"
```

---

## 🛡️ Production Security Reminders

1. **Never deploy directly to production** without staging validation
2. **Always use manual approval** workflows for production changes
3. **Regular security audits** of role assignments and access patterns
4. **Monitor costs** and set up billing alerts
5. **Keep infrastructure code** in version control with proper review process
6. **Document all changes** with justification and rollback procedures

**Next Steps**: After production setup, implement monitoring, alerting, and establish operational procedures for your production WalletWatch environment.