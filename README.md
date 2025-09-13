# WalletWatch Infrastructure as Code

This repository contains Terraform infrastructure code for deploying Azure Container Registry (ACR) resources with GitHub Actions automation.

## 🏗️ Project Structure

```
.
├── .github/workflows/          # GitHub Actions workflows
├── docs/                       # Documentation
├── infrastructure/             # Terraform infrastructure code
│   ├── modules/               # Reusable Terraform modules
│   │   ├── acr/              # Azure Container Registry module
│   │   └── resource-group/   # Resource Group module
│   ├── environments/         # Environment-specific configurations
│   │   ├── dev/             # Development environment
│   │   ├── staging/         # Staging environment
│   │   └── prod/           # Production environment
│   ├── main.tf             # Main Terraform configuration
│   ├── variables.tf        # Input variables
│   └── outputs.tf          # Output values
├── .github/workflows/       # GitHub Actions workflows
└── CLAUDE.md              # Claude Code guidance
```

## 🏗️ Provisioned Infrastructure

### Backend Resources (Manually Created)
- **Resource Group**: `terraform-state-rg` (West Europe)
- **Storage Account**: `tfstatewalletwatch`
- **Storage Container**: `tfstate`
- **Purpose**: Terraform remote state management with versioning and encryption

### Application Resources (Terraform Managed)
Currently configured to deploy:
- **Resource Groups**: Environment-specific (dev/staging/prod)
- **Azure Container Registry**: Environment-specific ACR instances
- **SKU Configuration**: Basic (dev), Standard (staging), Premium (prod)

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
1. **Service Principal Credentials**: Create via `az ad sp create-for-rbac`
2. **Tenant/Subscription IDs**: Found in Azure Portal → Azure Active Directory
3. **ARM_ACCESS_KEY**: Azure Portal → Storage Account → Access Keys

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
   terraform plan -var-file="environments/dev/terraform.tfvars" -var="subscription_id=YOUR_SUBSCRIPTION_ID"
   
   # Apply changes
   terraform apply -var-file="environments/dev/terraform.tfvars" -var="subscription_id=YOUR_SUBSCRIPTION_ID"
   
   # View outputs
   terraform output
   
   # Destroy infrastructure
   terraform destroy -var-file="environments/dev/terraform.tfvars" -var="subscription_id=YOUR_SUBSCRIPTION_ID"
   ```

4. **Quick environment switching:**
   ```bash
   # For different environments, change the var-file path:
   # Development
   terraform plan -var-file="environments/dev/terraform.tfvars" -var="subscription_id=YOUR_SUBSCRIPTION_ID"
   
   # Staging
   terraform plan -var-file="environments/staging/terraform.tfvars" -var="subscription_id=YOUR_SUBSCRIPTION_ID"
   
   # Production
   terraform plan -var-file="environments/prod/terraform.tfvars" -var="subscription_id=YOUR_SUBSCRIPTION_ID"
   ```

### GitHub Actions Deployment

See [GitHub Actions Setup Guide](docs/GITHUB_ACTIONS_SETUP.md) for automated deployment configuration.

## 📁 Environment Configuration

Each environment has its own configuration in `infrastructure/environments/`:

- **dev/**: Development environment with Basic ACR SKU
- **staging/**: Staging environment with Standard ACR SKU  
- **prod/**: Production environment with Premium ACR SKU

## 📚 Documentation

- [GitHub Actions Setup](docs/GITHUB_ACTIONS_SETUP.md) - Complete setup guide for automated deployments
- [CLAUDE.md](CLAUDE.md) - Development guidance for Claude Code

## 🛠️ Architecture

The infrastructure is organized using Terraform modules for reusability and maintainability:

- **Resource Group Module**: Manages Azure resource groups with consistent tagging
- **ACR Module**: Configures Azure Container Registry with environment-specific settings
- **Main Configuration**: Orchestrates modules and providers

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