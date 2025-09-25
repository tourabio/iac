# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a professionally structured Terraform-based Infrastructure as Code (IaC) project for deploying Azure Kubernetes Service (AKS) resources. The project follows best practices with modular architecture, environment separation, and automated CI/CD workflows.

## Architecture

- **Provider**: Azure Resource Manager (AzureRM) ~> 3.116.0
- **Structure**: Modular Terraform with environment separation
- **Deployment**: Enhanced GitHub Actions workflows with validation
- **State Management**: Azure Storage Backend with versioning and encryption

### Core Components

1. **Modules**: Reusable Terraform modules in `infrastructure/modules/`
   - `aks/`: Azure Kubernetes Service module with auto-scaling and persistent identities
   - `postgresql/`: PostgreSQL Flexible Server with environment-specific SKUs
   - `keyvault-secrets/`: Key Vault secrets management for database credentials
   - `public-dns/`: Free Azure domain management for external access
   - `dns/`, `domain/`: Additional DNS management capabilities
   - `resource-group/`: Azure Resource Group module
2. **Environments**: Environment-specific configurations
   - `dev/`: Development with single AKS node (auto-scaling 1-2), Basic PostgreSQL
   - `staging/`: Staging with auto-scaling (1-2 nodes), Standard PostgreSQL
   - `prod/`: Production with auto-scaling (1-3 nodes), Premium PostgreSQL
3. **Main Configuration**: `infrastructure/main.tf` orchestrates modules with persistent resource groups
4. **Workflows**: GitHub Actions for deployment, destruction, and scheduled cleanup

## Common Commands

### Using GitHub Actions (Recommended)

Infrastructure deployment is handled through GitHub Actions workflows:

1. **Manual deployment**: Use workflow dispatch for `create-infrastructure.yml`
2. **Environment selection**: Choose dev/staging/prod in workflow
3. **Manual approval**: Required via `{environment}-approval` environments
4. **Monitoring**: Check deployment status in GitHub Actions tab
5. **Scheduled cleanup**: Automatic nightly cleanup of dev/staging at 20:00 UTC
6. **Workflow triggers**: Create and destroy workflows are manually triggered only

### Direct Terraform Commands
```bash
# Navigate to infrastructure directory
cd infrastructure/

# Initialize Terraform
terraform init

# Plan for specific environment
terraform plan -var-file="environments/dev/terraform.tfvars" -var="subscription_id=YOUR_SUBSCRIPTION_ID"

# Apply changes
terraform apply -var-file="environments/dev/terraform.tfvars" -var="subscription_id=YOUR_SUBSCRIPTION_ID"

# Show outputs
terraform output

# Destroy infrastructure
terraform destroy -var-file="environments/dev/terraform.tfvars" -var="subscription_id=YOUR_SUBSCRIPTION_ID"
```

## Environment Configuration

Each environment has specific AKS configurations:
- **dev**: Single node with auto-scaling (1-2 nodes), Standard_B2s VMs
- **staging**: Auto-scaling enabled (1-2 nodes), Standard_B2s VMs
- **prod**: Auto-scaling enabled (1-3 nodes), Standard_B2s VMs

## GitHub Actions Workflows

### Enhanced Features
- Environment selection (dev/staging/prod)
- Security scanning with tfsec
- Terraform caching for performance
- Plan verification before apply
- Rich reporting with emojis and summaries
- GitHub releases for production deployments
- Comprehensive error handling

### Prerequisites

**Initial Setup:**
1. Create Azure backend storage manually or via Azure Portal
2. Configure GitHub Secrets (required for workflows)
3. Set up GitHub Environments for manual approval (see below)

**Required GitHub Secrets:**
- `ARM_CLIENT_ID` - Azure Service Principal Application ID
- `ARM_CLIENT_SECRET` - Azure Service Principal Secret  
- `ARM_TENANT_ID` - Azure Tenant ID
- `ARM_SUBSCRIPTION_ID` - Azure Subscription ID
- `ARM_ACCESS_KEY` - Storage Account Access Key (for Terraform backend)

**Required GitHub Environments (for manual approval):**
Create these environments in GitHub repository settings:
- `dev-approval` - For development deployments
- `staging-approval` - For staging deployments  
- `prod-approval` - For production deployments

For each environment:
1. Go to Settings → Environments → New environment
2. Add environment name (e.g., `dev-approval`)
3. Enable "Required reviewers" protection rule
4. Add yourself as a required reviewer
5. Save protection rules

### Deployment Workflow (`create-infrastructure.yml`)
**Sections**:
1. **Validation and Security Checks**: Format, validate, security scan
2. **Infrastructure Planning**: Terraform plan with environment selection
3. **Infrastructure Deployment**: Apply with verification and outputs
4. **Post-Deployment Notifications**: Status reporting and releases

### Destruction Workflow (`destroy-infrastructure.yml`)
**Sections**:
1. **Pre-Destruction Validation**: Resource checking and destroy planning
2. **Infrastructure Destruction**: Safe destruction with manual approval
3. **Post-Destruction Verification**: Completion status and cleanup

### Scheduled Cleanup Workflow (`scheduled-destroy-infrastructure.yml`)
**Sections**:
1. **Automated Dev Cleanup**: Nightly cleanup of dev environment (20:00 UTC)
2. **Automated Staging Cleanup**: Sequential staging environment cleanup
3. **Cost Optimization**: Prevents overnight resource costs in non-production environments

## Project Structure

```
.
├── .github/workflows/          # GitHub Actions workflows
│   ├── create-infrastructure.yml     # Infrastructure deployment
│   ├── destroy-infrastructure.yml    # Infrastructure destruction
│   └── scheduled-destroy-infrastructure.yml  # Nightly cleanup
├── docs/                       # Documentation
│   ├── GITHUB_ACTIONS_SETUP.md
│   └── learning.md
├── infrastructure/             # Terraform infrastructure code
│   ├── modules/               # Reusable modules
│   │   ├── aks/              # Azure Kubernetes Service
│   │   ├── dns/              # DNS zone management
│   │   ├── domain/           # Domain configuration
│   │   ├── keyvault-secrets/ # Key Vault secrets management
│   │   ├── postgresql/       # PostgreSQL Flexible Server
│   │   ├── public-dns/       # Public DNS with Azure domains
│   │   └── resource-group/   # Resource Group module
│   ├── environments/         # Environment-specific configs
│   │   ├── dev/terraform.tfvars
│   │   ├── staging/terraform.tfvars
│   │   └── prod/terraform.tfvars
│   ├── main.tf               # Main configuration with modules
│   ├── variables.tf          # Input variables with validation
│   └── outputs.tf            # Module outputs
└── README.md                  # Project overview
```

## Security and Best Practices

- **Modular Design**: Reusable modules with input validation
- **Environment Separation**: Dedicated configs per environment
- **Security Scanning**: Automated tfsec security checks
- **Sensitive Handling**: Proper handling of sensitive variables
- **Approval Workflows**: Manual approval for production changes
- **State Management**: Backup and archiving strategies
- **Tagging Strategy**: Consistent resource tagging

## Required Admin Setup for Infrastructure

### Pre-Created Persistent Resources

The infrastructure requires the following manually created resources:

**For Each Environment (dev/staging/prod):**

1. **Persistent Resource Group**: `walletwatch-<env>-persistent-rg` (contains identities, ACR, Key Vault)
2. **Main Resource Group**: `walletwatch-<env>-rg` (contains AKS, PostgreSQL, compute resources - manually created but referenced by Terraform)
3. **Kubelet Identity**: `walletwatch-<env>-aks-kubelet-identity` (for ACR access)
4. **Control Plane Identity**: `walletwatch-<env>-aks-controlplane-identity` (for AKS management)
5. **Azure Container Registry**: `walletwatch<env>acr` (manually created)
6. **Key Vault**: `walletwatch-<env>-kv` (optional, for secrets management)

### Required Role Assignments (One-Time Setup)

**Critical Role Assignments by Admin:**
1. **Control Plane Identity → Kubelet Identity**: "Managed Identity Operator" role
   - Enables AKS cluster creation with user-assigned identities
   - Required to solve CustomKubeletIdentityMissingPermissionError
2. **Kubelet Identity → ACR**: "AcrPull" role (for container image access)
3. **Kubelet Identity → Key Vault**: "Key Vault Secrets User" role (if using Key Vault)
4. **AKS Cluster Identity → Resource Group**: "Network Contributor" role
   - Enables LoadBalancer services to access and assign Azure public IPs
   - Required for NGINX ingress controller external IP assignment
   - Prevents "AuthorizationFailed" errors when creating LoadBalancer services

**Admin Commands Reference:**

**Step 1: Create Main Resource Groups (One-Time)**
```bash
# Dev environment
az group create --name "walletwatch-dev-rg" --location "France Central"

# Staging environment
az group create --name "walletwatch-staging-rg" --location "West Europe"

# Production environment
az group create --name "walletwatch-prod-rg" --location "West Europe"
```

**Step 2: Role Assignments (One-Time Per Environment)**
```bash
# Grant control plane identity permission to manage kubelet identity
az role assignment create \
  --assignee <controlplane-identity-principal-id> \
  --role "Managed Identity Operator" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/walletwatch-<env>-persistent-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/walletwatch-<env>-aks-kubelet-identity"

# Grant kubelet identity access to Key Vault
az role assignment create \
  --assignee <kubelet-identity-principal-id> \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/walletwatch-<env>-persistent-rg/providers/Microsoft.KeyVault/vaults/walletwatch-<env>-kv"

# CRITICAL: Grant AKS control plane identity Network Contributor role (ONE-TIME SETUP)
az role assignment create \
  --assignee <controlplane-identity-principal-id> \
  --role "Network Contributor" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/walletwatch-<env>-rg"
```

**Development Environment Example:**
```bash
# Replace with your actual values for dev environment
az role assignment create \
  --assignee "fa229838-37ee-454c-a3f6-d9b14130d90a" \
  --role "Network Contributor" \
  --scope "/subscriptions/56637f11-5e83-404d-b6b3-04c7dab01412/resourceGroups/walletwatch-dev-rg"
```

### Why This Architecture

- **Persistence**: All role assignments survive terraform destroy/redeploy cycles
- **Security**: Minimal permissions following principle of least privilege
- **Separation**: Control plane and kubelet have distinct identities and roles
- **Admin Control**: Critical resources managed outside of developer terraform state
- **nginx-ingress Reliability**: Network Contributor role on persistent main resource groups ensures LoadBalancer services work immediately after deployment

See detailed setup instructions in `docs/learning.md` - "AKS Control Plane Identity and Managed Identity Operator Permissions" section.

## Documentation Requirements
IMPORTANT: When adding new infrastructure resources or GitHub Actions secrets:
1. ALWAYS update the README.md "🏗️ Provisioned Infrastructure" section
2. ALWAYS update the README.md "🔐 GitHub Actions Secrets" section
3. Document what each resource does and why it's needed
4. Include instructions for obtaining secret values
5. Keep the resource inventory current and accurate