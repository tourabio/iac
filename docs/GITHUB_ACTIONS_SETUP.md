# GitHub Actions Setup for Terraform Infrastructure

This document explains how to set up GitHub Actions workflows for managing your Azure infrastructure with Terraform.

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

### Azure Service Principal Secrets

1. **ARM_CLIENT_ID** - Azure Service Principal Application ID
2. **ARM_CLIENT_SECRET** - Azure Service Principal Secret
3. **ARM_TENANT_ID** - Azure Tenant ID
4. **ARM_SUBSCRIPTION_ID** - Azure Subscription ID
5. **ARM_ACCESS_KEY** - Storage Account Access Key for Terraform backend

### How to Create Azure Service Principal

1. **Login to Azure CLI:**
   ```bash
   az login
   ```

2. **Create Service Principal:**
   ```bash
   az ad sp create-for-rbac --name "terraform-github-actions" \
     --role="Contributor" \
     --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
   ```

3. **Note the output values:**
   ```json
   {
     "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
     "displayName": "terraform-github-actions",
     "password": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
     "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   }
   ```

4. **Map the values to GitHub secrets:**
   - `appId` → `ARM_CLIENT_ID`
   - `password` → `ARM_CLIENT_SECRET`
   - `tenant` → `ARM_TENANT_ID`
   - Your subscription ID → `ARM_SUBSCRIPTION_ID`

5. **Get Storage Account Access Key:**
   ```bash
   az storage account keys list --resource-group terraform-state-rg --account-name tfstatewalletwatch --query '[0].value' --output tsv
   ```
   - Copy this value → `ARM_ACCESS_KEY`

### Adding Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the corresponding name and value

## GitHub Environment Setup

The deployment workflows use GitHub environments with manual approval for each target environment.

### Create Environments:

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Create the following environments:
   - `dev-approval` (for development deployments)
   - `staging-approval` (for staging deployments)
   - `prod-approval` (for production deployments)
4. For each environment:
   - Configure **Required reviewers** (add yourself or team members)
   - Save the environment

## Workflows Overview

### 1. Create Infrastructure (`create-infrastructure.yml`)

- **Trigger**: Manual dispatch with environment selection
- **Environment Selection**: Choose dev/staging/prod
- **Steps**:
  1. **Validation**: Format check, validate, security scan
  2. **Plan**: Creates Terraform plan and shows what will be created
  3. **Approval**: Waits for manual approval in `{environment}-approval` environment
  4. **Apply**: Applies the changes after approval
- **Manual Approval**: Required before applying changes

### 2. Destroy Infrastructure (`destroy-infrastructure.yml`)

- **Trigger**: Manual dispatch with environment selection
- **Environment Selection**: Choose dev/staging/prod to destroy
- **Steps**:
  1. **Show Plan**: Creates and displays destroy plan
  2. **Approval**: Waits for manual approval in `{environment}-approval` environment
  3. **Execute**: Destroys infrastructure after approval
- **Manual Approval**: Required before destruction

### 3. Scheduled Cleanup (`scheduled-destroy-infrastructure.yml`)

- **Trigger**: Scheduled (nightly at 20:00 UTC)
- **Purpose**: Cost optimization by cleaning up dev and staging environments
- **Steps**:
  1. **Cleanup Dev**: Automatically destroys dev environment
  2. **Cleanup Staging**: Automatically destroys staging environment (after dev)
- **No Approval**: Fully automated for cost savings

## Usage

### Deploy Infrastructure:

1. Go to **Actions** tab in your repository
2. Select **🚀 Deploy Infrastructure** workflow
3. Click **Run workflow**
4. Select target environment (dev/staging/prod)
5. Review the plan in the workflow summary
6. Approve the deployment in the **{environment}-approval** environment

### Destroy Infrastructure:

1. Go to **Actions** tab in your repository
2. Select **🗑️ Destroy Infrastructure** workflow
3. Click **Run workflow**
4. Select target environment (dev/staging/prod)
5. Review the destroy plan
6. Approve the destruction in the **{environment}-approval** environment

### Monitor Scheduled Cleanup:

1. Go to **Actions** tab in your repository
2. Select **🕒 Scheduled Infrastructure Cleanup** workflow
3. View automatic nightly cleanup runs (20:00 UTC)
4. No manual intervention required - fully automated

## Security Notes

- Service Principal has Contributor role on the subscription
- Secrets are encrypted and only accessible to workflows
- Manual approval required for deployments
- Confirmation required for destruction
- All operations are logged in GitHub Actions

## Troubleshooting

### Common Issues:

1. **Authentication Failed**: Check that all ARM_* secrets are correctly set
2. **Permission Denied**: Ensure Service Principal has Contributor role
3. **Plan Shows No Changes**: Check if resources already exist
4. **Workflow Doesn't Run**: Verify workflow files are in `.github/workflows/`

### Debug Steps:

1. Check workflow logs in Actions tab
2. Verify secrets are set correctly
3. Test Azure CLI authentication locally with same credentials
4. Ensure Terraform state is consistent