# WalletWatch Infrastructure as Code

This repository contains Terraform infrastructure code for deploying Azure Kubernetes Service (AKS) resources with GitHub Actions automation.

## 🏗️ Project Structure

```
.
├── .github/workflows/          # GitHub Actions workflows
│   ├── create-infrastructure.yml     # Infrastructure deployment
│   ├── destroy-infrastructure.yml    # Infrastructure destruction
│   └── scheduled-destroy-infrastructure.yml  # Nightly cleanup
├── docs/                       # Documentation
│   ├── GITHUB_ACTIONS_SETUP.md      # GitHub Actions setup guide
│   └── learning.md                  # Learning notes and discoveries
├── infrastructure/             # Terraform infrastructure code
│   ├── modules/               # Reusable Terraform modules
│   │   ├── aks/              # Azure Kubernetes Service
│   │   ├── dns/              # DNS zone management
│   │   ├── domain/           # Domain configuration
│   │   ├── keyvault-secrets/ # Key Vault secrets management
│   │   ├── postgresql/       # PostgreSQL Flexible Server
│   │   ├── public-dns/       # Public DNS with Azure domains
│   │   └── resource-group/   # Resource Group module
│   ├── environments/         # Environment-specific configurations
│   │   ├── dev/             # Development environment
│   │   ├── staging/         # Staging environment
│   │   └── prod/           # Production environment
│   ├── main.tf             # Main Terraform configuration
│   ├── variables.tf        # Input variables
│   └── outputs.tf          # Output values
└── CLAUDE.md              # Claude Code guidance
```

## 🏗️ Provisioned Infrastructure

### Backend Resources (Manually Created)
- **Resource Group**: `terraform-state-francecentral-rg` (France Central)
- **Storage Account**: `tfstatefrancecentralww`
- **Storage Container**: `tfstate`
- **Purpose**: Terraform remote state management with versioning and encryption

### Application Resources (Terraform Managed)
Currently configured to deploy:
- **Resource Groups**: Environment-specific (dev/staging/prod)
- **Azure Kubernetes Service**: Environment-specific AKS clusters with auto-scaling
- **PostgreSQL Flexible Server**: Managed database service with environment-specific SKUs
- **Azure Container Registry**: Pre-created in persistent resource groups
- **Key Vault Integration**: Secrets management with role-based access
- **Public DNS**: Free Azure domain integration for external access
- **Node Configuration**: Auto-scaling enabled with cost-effective VM sizes

## 🔐 GitHub Actions Secrets

### Required Secrets for CI/CD
```
ARM_CLIENT_ID=<azure-service-principal-app-id>
ARM_CLIENT_SECRET=<azure-service-principal-secret>
ARM_TENANT_ID=<azure-tenant-id>
ARM_SUBSCRIPTION_ID=<azure-subscription-id>
ARM_ACCESS_KEY=<storage-account-access-key>
```

### How to Get Secret Values
1. **Service Principal Credentials**: Create via `az ad sp create-for-rbac --name "terraform-github-actions" --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID"`
2. **Tenant/Subscription IDs**: Found in Azure Portal → Azure Active Directory
3. **ARM_ACCESS_KEY**: Azure Portal → Storage Account (`tfstatefrancecentralww`) → Access Keys → key1 value

## 🚀 Quick Start

### Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) >= 0.14
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with Contributor permissions
- Terraform backend storage created (see above)

### Local Development

1. **Clone and navigate:**
   ```bash
   git clone <repository-url>
   cd iac
   ```

2. **Using GitHub Actions (Recommended):**

   Infrastructure deployment is handled through GitHub Actions:
   - Use manual workflow dispatch to trigger deployment
   - Select target environment (dev/staging/prod) in workflow
   - Monitor progress in GitHub Actions tab
   - Both create and destroy workflows are manually triggered

3. **Manual Terraform commands:**
   ```bash
   # Navigate to infrastructure directory
   cd infrastructure
   
   # Initialize Terraform
   terraform init
   
   # Plan deployment for development
   terraform plan -var-file="environments/dev/terraform.tfvars" -var="subscription_id=SUBSCRIPTION_ID"
   
   # Apply changes
   terraform apply -var-file="environments/dev/terraform.tfvars" -var="subscription_id=SUBSCRIPTION_ID"
   
   # View outputs
   terraform output
   
   # Destroy infrastructure
   terraform destroy -var-file="environments/dev/terraform.tfvars" -var="subscription_id=SUBSCRIPTION_ID"
   ```

4. **Quick environment switching:**
   ```bash
   # For different environments, change the var-file path:
   # Development
   terraform plan -var-file="environments/dev/terraform.tfvars" -var="subscription_id=SUBSCRIPTION_ID"
   
   # Staging
   terraform plan -var-file="environments/staging/terraform.tfvars" -var="subscription_id=SUBSCRIPTION_ID"
   
   # Production
   terraform plan -var-file="environments/prod/terraform.tfvars" -var="subscription_id=SUBSCRIPTION_ID"
   ```

### GitHub Actions Deployment

See [GitHub Actions Setup Guide](docs/GITHUB_ACTIONS_SETUP.md) for automated deployment configuration.

## 📁 Environment Configuration

Each environment has its own configuration in `infrastructure/environments/`:

- **dev/**: Development environment with single AKS node
- **staging/**: Staging environment with auto-scaling (1-2 nodes)
- **prod/**: Production environment with auto-scaling (1-3 nodes)

## 📚 Documentation

- [GitHub Actions Setup](docs/GITHUB_ACTIONS_SETUP.md) - Complete setup guide for automated deployments
- [CLAUDE.md](CLAUDE.md) - Development guidance for Claude Code

## 🛠️ Architecture

The infrastructure is organized using Terraform modules for reusability and maintainability:

- **Resource Group Module**: Manages Azure resource groups with consistent tagging
- **AKS Module**: Configures Azure Kubernetes Service with auto-scaling and monitoring
- **PostgreSQL Module**: Manages PostgreSQL Flexible Server with environment-specific configurations
- **Key Vault Secrets Module**: Handles database credential management and secure storage
- **Public DNS Module**: Manages free Azure domain for external service access
- **DNS/Domain Modules**: Additional DNS management capabilities
- **Main Configuration**: Orchestrates modules and providers with environment separation

## 🔒 Security Features

- Service principal authentication for GitHub Actions
- Environment-based approval workflows
- Sensitive variable handling
- Resource provider registration
- Consistent tagging strategy

## 🤝 Contributing

1. Create feature branch
2. Make changes with proper testing
3. Update documentation as needed
4. Submit pull request

## 📄 License

This project is part of WalletWatch and follows the event's guidelines.