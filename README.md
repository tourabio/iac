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
├── scripts/                # Utility scripts
└── CLAUDE.md              # Claude Code guidance
```

## 🚀 Quick Start

### Prerequisites
- [Terraform](https://www.terraform.io/downloads.html) >= 0.14
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Azure subscription with appropriate permissions

### Local Development

1. **Clone and navigate:**
   ```bash
   git clone <repository-url>
   cd iac
   ```

2. **Using deployment scripts (Recommended):**
   ```bash
   # Make scripts executable (Linux/macOS)
   chmod +x scripts/*.sh
   
   # Deploy to development
   ./scripts/deploy.sh dev YOUR_SUBSCRIPTION_ID
   
   # Deploy to staging
   ./scripts/deploy.sh staging YOUR_SUBSCRIPTION_ID
   
   # Deploy to production
   ./scripts/deploy.sh prod YOUR_SUBSCRIPTION_ID
   ```

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