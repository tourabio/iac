# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a professionally structured Terraform-based Infrastructure as Code (IaC) project for deploying Azure Container Registry (ACR) resources. The project follows best practices with modular architecture, environment separation, and automated CI/CD workflows.

## Architecture

- **Provider**: Azure Resource Manager (AzureRM) v3.67.0
- **Structure**: Modular Terraform with environment separation
- **Deployment**: Enhanced GitHub Actions workflows with validation
- **State Management**: Azure Storage Backend with versioning and encryption

### Core Components

1. **Modules**: Reusable Terraform modules in `infrastructure/modules/`
   - `resource-group/`: Azure Resource Group module
   - `acr/`: Azure Container Registry module with validation
2. **Environments**: Environment-specific configurations
   - `dev/`: Development with Basic SKU
   - `staging/`: Staging with Standard SKU  
   - `prod/`: Production with Premium SKU
3. **Main Configuration**: `infrastructure/main.tf` orchestrates modules
4. **Scripts**: Utility scripts for deployment and destruction

## Common Commands

### Using GitHub Actions (Recommended)

Infrastructure deployment is handled through GitHub Actions workflows:

1. **Manual deployment**: Use workflow dispatch in GitHub Actions
2. **Environment selection**: Choose dev/staging/prod in workflow
3. **Monitoring**: Check deployment status in GitHub Actions tab
4. **Workflow triggers**: Both create and destroy workflows are manually triggered only

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

Each environment has specific resource names and SKUs:
- **dev**: `walletwatchdevacr` with Basic SKU
- **staging**: `walletwatchstagingacr` with Standard SKU
- **prod**: `walletwatchprodacr` with Premium SKU

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
2. **Infrastructure Destruction**: Safe destruction with backups
3. **Edge Cases and Error Handling**: Handle empty states and errors
4. **Post-Destruction Notifications**: Completion status and cleanup

## Project Structure

```
.
├── .github/workflows/          # Enhanced GitHub Actions workflows
├── docs/                       # Documentation
│   ├── GITHUB_ACTIONS_SETUP.md
│   └── README.md
├── infrastructure/             # Terraform infrastructure code
│   ├── modules/               # Reusable modules
│   │   ├── acr/              # ACR module with validation
│   │   └── resource-group/   # Resource Group module
│   ├── environments/         # Environment-specific configs
│   │   ├── dev/terraform.tfvars
│   │   ├── staging/terraform.tfvars
│   │   └── prod/terraform.tfvars
│   ├── main.tf               # Main configuration with modules
│   ├── variables.tf          # Input variables with validation
│   └── outputs.tf            # Module outputs
├── scripts/                    # Utility scripts
│   ├── deploy.sh              # Deployment script
│   └── destroy.sh             # Destruction script
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

## Documentation Requirements
IMPORTANT: When adding new infrastructure resources or GitHub Actions secrets:
1. ALWAYS update the README.md "🏗️ Provisioned Infrastructure" section
2. ALWAYS update the README.md "🔐 GitHub Actions Secrets" section  
3. Document what each resource does and why it's needed
4. Include instructions for obtaining secret values
5. Keep the resource inventory current and accurate