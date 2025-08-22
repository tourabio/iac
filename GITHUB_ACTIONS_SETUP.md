# GitHub Actions Setup for Terraform Infrastructure

This document explains how to set up GitHub Actions workflows for managing your Azure infrastructure with Terraform.

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

### Azure Service Principal Secrets

1. **ARM_CLIENT_ID** - Azure Service Principal Application ID
2. **ARM_CLIENT_SECRET** - Azure Service Principal Secret
3. **ARM_TENANT_ID** - Azure Tenant ID
4. **ARM_SUBSCRIPTION_ID** - Azure Subscription ID

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

### Adding Secrets to GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the corresponding name and value

## GitHub Environment Setup

The deployment workflow uses a GitHub environment called `production` for manual approval.

### Create Environment:

1. Go to **Settings** → **Environments**
2. Click **New environment**
3. Name it `production`
4. Configure **Required reviewers** (add yourself or team members)
5. Save the environment

## Workflows Overview

### 1. Deploy Infrastructure (`terraform-deploy.yml`)

- **Trigger**: Manual dispatch
- **Steps**:
  1. **Plan**: Creates Terraform plan and shows what will be created
  2. **Apply**: Waits for manual approval, then applies the changes
- **Manual Approval**: Required before applying changes

### 2. Destroy Infrastructure (`terraform-destroy.yml`)

- **Trigger**: Manual dispatch with confirmation
- **Safety**: Requires typing "destroy" to confirm
- **Steps**:
  1. Shows destroy plan
  2. Destroys all infrastructure

## Usage

### Deploy Infrastructure:

1. Go to **Actions** tab in your repository
2. Select **Deploy Infrastructure** workflow
3. Click **Run workflow**
4. Review the plan in the workflow summary
5. Approve the deployment in the **production** environment

### Destroy Infrastructure:

1. Go to **Actions** tab in your repository
2. Select **Destroy Infrastructure** workflow
3. Click **Run workflow**
4. Type `destroy` in the confirmation field
5. Click **Run workflow**

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