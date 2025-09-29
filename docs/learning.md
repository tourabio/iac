# Learning Notes - Infrastructure as Code Journey

## What is Terraform?

Terraform is an Infrastructure as Code (IaC) tool that allows you to define and provision cloud infrastructure using declarative configuration files. Instead of manually clicking through cloud portals, you write code that describes your desired infrastructure state, and Terraform creates it for you.

**Key Benefits:**
- **Reproducible**: Same infrastructure every time
- **Version controlled**: Track changes over time
- **Automated**: Deploy with CI/CD pipelines
- **Multi-cloud**: Works with AWS, Azure, GCP, etc.

## Our Project Structure

### State Management Challenge
We learned that Terraform needs somewhere to store its "state" - a record of what resources it has created. 

**The Problem:**
- Local state files don't work for teams or CI/CD
- Each workflow run would be isolated and couldn't track previous deployments

**Our Solution:**
- **Azure Storage Backend**: Remote state storage in Azure
- **Persistent across deployments**: All workflows share the same state
- **Professional approach**: Industry standard for production environments

### Modular Architecture
```
infrastructure/
├── modules/           # Reusable components
│   ├── aks/          # Azure Kubernetes Service
│   ├── public-dns/   # Free Azure domain for ArgoCD
│   └── resource-group/
├── environments/     # Environment-specific configs
│   ├── dev/
│   ├── staging/
│   └── prod/
└── main.tf          # Orchestrates everything
```

**Why this matters:**
- **DRY principle**: Don't Repeat Yourself
- **Environment consistency**: Same modules, different configurations
- **Maintainability**: Change once, apply everywhere

## GitHub Actions Manual Approval Discovery

### The Repository Type Limitation

**Key Finding:** GitHub Environment Protection Rules (manual approval buttons) are **NOT available for private repositories on free plans**.

**What works:**
- ✅ **Public repositories** → Full environment protection rules
- ✅ **Private repos with GitHub Pro/Team/Enterprise** → Full protection rules
- ❌ **Private repos on free plan** → No protection rules

### Our Implementation
We structured our workflows with manual approval steps:

**Create Infrastructure:**
1. Validate & Plan → 2. **Manual Approval** → 3. Apply

**Destroy Infrastructure:**
1. Validate → 2. **Manual Approval (with danger warnings)** → 3. Execute Destruction

**Environment Setup Required:**
- Create environments: `dev-approval`, `staging-approval`, `prod-approval`
- Enable "Required reviewers" protection rule
- Add yourself as reviewer

### The Approval Experience
When configured properly:
- ⏸️ Workflow pauses at approval step
- 🔘 "Review deployments" button appears
- ✅ Click approve/reject to continue/cancel
- 🚀 Infrastructure changes only happen after conscious approval

## Key Takeaways

1. **State management is critical** - Use remote backends for production
2. **Modular design scales better** - Separate concerns and reuse components  
3. **Manual approval requires the right GitHub plan** - Public repos or paid plans
4. **Destruction needs extra safety** - More warnings, same approval mechanism
5. **Professional IaC requires proper CI/CD** - Not just local development

## Azure Permissions and Role Assignment Challenges

### The Service Principal Authorization Issue

**Key Finding:** Service principals created by users may not have sufficient permissions to create role assignments, even with Contributor access.

**The Problem:**
- AKS clusters need to pull images from Azure Container Registry (ACR)
- This requires creating a role assignment for the AKS managed identity
- Service principals need **User Access Administrator** role to create role assignments
- Many organizations restrict this high-privilege role

**Our Solution:**

**Persistent User-Assigned Managed Identities with Admin Role Assignments**
- Developer manually creates all persistent resources: resource groups, identities, ACR, Key Vault using Azure CLI
- Admin only grants required role assignments once between the created resources
- Admin grants control plane identity "Managed Identity Operator" role on kubelet identity
- Admin grants kubelet identity "Key Vault Secrets User" role on the manually created Key Vault
- Terraform references existing persistent resources instead of creating them
- Service principal (created by admin) has Contributor access for ephemeral resource creation but not role assignment permissions

### Key Lessons

1. **Not all Azure operations can be automated** - Some require higher privileges
2. **Manual steps aren't always bad** - Sometimes they're more secure
3. **Azure CLI commands can handle permissions** - `--attach-acr` manages roles automatically
4. **Separation of concerns works** - Infrastructure creation vs. permission assignment
5. **Document manual steps clearly** - Include them in deployment runbooks

## DNS and Domain Management with Terraform

### The Challenge: External Access to Kubernetes Services

**Key Finding:** Getting external access to Kubernetes applications requires proper DNS configuration, which can be automated with Terraform.

**The Problem:**
- Kubernetes services need external access (ArgoCD UI, application endpoints)
- LoadBalancer services get dynamic IP addresses from cloud providers
- Manual DNS configuration is error-prone and not reproducible
- SSL certificates need proper domain names to work

**Our Solution: Azure DNS Integration**

**Step 1: DNS Zone Creation**
```hcl
resource "azurerm_dns_zone" "main" {
  name                = var.domain_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
```

**Step 2: Dynamic DNS Records**
```hcl
# Get LoadBalancer IP from Kubernetes
data "kubernetes_service" "nginx_ingress" {
  metadata {
    name      = "nginx-ingress-ingress-nginx-controller"
    namespace = "nginx-ingress"
  }
}

# Create A record pointing to LoadBalancer IP
resource "azurerm_dns_a_record" "argocd" {
  name                = "argocd-${var.environment}"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [data.kubernetes_service.nginx_ingress.status.0.load_balancer.0.ingress.0.ip]
}
```

### Single-Phase Deployment with Free Azure Domain

**Simplified Approach:**
- Deploy AKS cluster, ACR, and free Azure public IP
- Use Azure's cloudapp.azure.com domain (no ownership required)
- ArgoCD accessible via: `argocd-dev-walletwatch.francecentral.cloudapp.azure.com`
- No DNS delegation or domain purchase needed

### Key Architecture Decisions

**Modular Public DNS Module:**
```
modules/public-dns/
├── main.tf      # Azure public IP with domain label
├── variables.tf # Configuration options
└── outputs.tf   # Public IP and Azure domain
```

**Environment-Specific Azure Domains:**
- Dev: `argocd-dev-walletwatch.francecentral.cloudapp.azure.com`
- Staging: `argocd-staging-walletwatch.francecentral.cloudapp.azure.com`
- Prod: `argocd-prod-walletwatch.francecentral.cloudapp.azure.com`

**Simplified Architecture:**
- Single public IP resource with domain label
- No complex DNS zone management
- Immediate domain availability

### Integration with Let's Encrypt

**Automatic SSL Certificates:**
- DNS records enable domain validation
- Cert-Manager uses DNS records for ACME challenges
- No manual certificate management needed

**ArgoCD Configuration:**
```yaml
server:
  ingress:
    enabled: true
    hosts:
      - argocd-dev-walletwatch.francecentral.cloudapp.azure.com
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

### Key Lessons

1. **Simplicity wins** - Free Azure domains avoid complexity of DNS delegation
2. **Terraform data sources are powerful** - Read live Kubernetes state
3. **Public IP with domain labels** - Azure provides free domain-like access
4. **No domain ownership required** - Use cloudapp.azure.com subdomains
5. **Single-phase deployment** - Everything deploys together
6. **SSL automation works with Azure domains** - Let's Encrypt works with cloudapp.azure.com

### Operational Considerations

**Free Azure Domain Benefits:**
- No domain registration costs
- Immediate availability (no propagation delay)
- Automatic DNS resolution
- Works globally with Azure infrastructure

**Cost Implications:**
- Public IP: ~$4/month per static IP
- No additional DNS costs
- No domain registration fees
- Total cost much lower than custom domains

## Persistent Main Resource Groups: The Final Solution

### The Problem: Role Assignment Scope Invalidation

**Key Discovery:** Azure role assignments are tied to specific resource instance IDs, not just names. When Terraform destroys and recreates a resource group, even with the same name, it gets a new resource ID, which invalidates existing role assignments.

**The Previous Approach Issues:**
- Role assigned to: Identity → "Network Contributor" → `/subscriptions/.../resourceGroups/walletwatch-dev-rg` (Resource ID: xyz123)
- `terraform destroy` → Resource Group with ID xyz123 deleted
- `terraform apply` → New Resource Group created with same name but different ID: abc789
- Role assignment still pointed to deleted resource ID xyz123
- nginx-ingress LoadBalancer services failed with authorization errors

### The Final Architecture Solution

**Dual Resource Group Strategy:**
1. **Persistent Resource Group**: `walletwatch-dev-persistent-rg` (identities, ACR, Key Vault)
2. **Persistent Main Resource Group**: `walletwatch-dev-rg` (compute resources - manually created, Terraform references)

**Implementation:**
- **Admin creates main RG manually**: `az group create --name "walletwatch-dev-rg"`
- **Admin assigns role once**: Identity → Network Contributor → Main RG scope
- **Terraform references existing RG**: Uses `data "azurerm_resource_group"` instead of `resource`
- **terraform destroy**: Only destroys resources inside RG, never the container RG
- **Role assignments persist**: Same RG instance ID means role scopes remain valid

### Technical Implementation

**Before (Resource Creation):**
```hcl
resource "azurerm_resource_group" "default" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
```

**After (Data Source Reference):**
```hcl
# Reference existing manually created resource group
data "azurerm_resource_group" "default" {
  name = var.resource_group_name
}
```

### Key Benefits Achieved

1. **True Role Assignment Persistence**: Network Contributor role survives all terraform destroy/apply cycles
2. **Immediate nginx-ingress Functionality**: LoadBalancer services work on first deployment without manual intervention
3. **Developer Autonomy**: Can destroy/recreate infrastructure without admin involvement
4. **Clean Separation**: Identities/ACR in persistent RGs, compute in main RGs
5. **Environment Consistency**: Same pattern works across dev/staging/prod

### Operational Workflow

**Admin Setup (Once Per Environment):**
1. Create main resource group manually: `az group create --name "walletwatch-dev-rg"`
2. Assign Network Contributor role to control plane identity on main RG scope (one-time)

**Developer/CI Operations (Repeatable):**
1. Run `terraform apply` → Creates AKS, PostgreSQL, etc. in existing RG
2. Run `terraform destroy` → Removes all resources but preserves container RG
3. nginx-ingress works immediately on every deployment

### Lessons Learned

1. **Azure Resource IDs are immutable**: Resource recreation means new IDs and broken role assignments
2. **Terraform state vs Azure state**: Terraform destroy doesn't always mean Azure resource deletion
3. **Data sources enable persistence**: Reference existing resources instead of creating them
4. **Role assignment scopes matter**: Persistent resources need persistent scopes
5. **Admin boundaries solve complex problems**: Some resources are better managed outside automation

This architecture finally solves the nginx-ingress authorization problem with a sustainable, scalable approach that works across all environments and deployment cycles.

## Terraform State Backend Migration: Geographic Consolidation

### The Problem: State and Resources in Different Regions

**Key Finding:** Having Terraform state backend in a different Azure region than deployed resources creates unnecessary latency and goes against data residency best practices.

**Our Situation:**
- **Original State Backend**: `terraform-state-rg` in West Europe with storage account `tfstatewalletwatch`
- **Application Resources**: All environments (dev/staging/prod) deployed in France Central
- **Impact**: Slower terraform operations due to cross-region state access

### The Migration Process

**Goal:** Move Terraform state backend from West Europe to France Central to match application resources location.

**Step 1: Create New State Backend in France Central**
```bash
# Create new resource group in target region
az group create \
  --name "terraform-state-francecentral-rg" \
  --location "France Central"

# Create new storage account with versioning enabled
az storage account create \
  --name "tfstatefrancecentralww" \
  --resource-group "terraform-state-francecentral-rg" \
  --location "France Central" \
  --sku "Standard_LRS" \
  --kind "StorageV2" \
  --allow-blob-public-access false \
  --min-tls-version "TLS1_2"

# Create container for state files
az storage container create \
  --name "tfstate" \
  --account-name "tfstatefrancecentralww" \
  --auth-mode login

# Enable versioning for state file protection
az storage account blob-service-properties update \
  --account-name "tfstatefrancecentralww" \
  --enable-versioning true

# Get access key for GitHub Actions secret
az storage account keys list \
  --resource-group "terraform-state-francecentral-rg" \
  --account-name "tfstatefrancecentralww" \
  --query '[0].value' \
  --output tsv
```

**Step 2: Update GitHub Actions Configuration**
```bash
# Update GitHub repository secret with new storage account access key
# Repository Settings > Secrets and variables > Actions > ARM_ACCESS_KEY
```

**Step 3: Update Terraform Backend Configuration**
```hcl
# infrastructure/main.tf - Backend block update
backend "azurerm" {
  resource_group_name  = "terraform-state-francecentral-rg"  # Changed from "terraform-state-rg"
  storage_account_name = "tfstatefrancecentralww"            # Changed from "tfstatewalletwatch"
  container_name       = "tfstate"                          # Unchanged
  key                  = "walletwatch.tfstate"              # Unchanged
}
```

**Step 4: State Migration Execution**
```bash
# Navigate to Terraform configuration directory
cd infrastructure

# Initialize with new backend and migrate existing state
terraform init -migrate-state

# Verification: Confirm state migration was successful
terraform plan -var-file="environments/dev/terraform.tfvars" -var="subscription_id=<YOUR_SUBSCRIPTION_ID>"
```

**Step 5: Cleanup Old Backend (After Verification)**
```bash
# After confirming successful migration and new backend works
az group delete --name "terraform-state-rg" --yes
```

### Migration Success Indicators

**Successful Migration Confirmed By:**
1. **terraform init -migrate-state** completed without errors
2. **terraform plan** executed successfully against new backend
3. **State file visible** in new storage account container
4. **GitHub Actions workflows** running successfully with new backend
5. **All environment deployments** working normally

### Key Benefits Achieved

1. **Geographic Consistency**: State backend and application resources now both in France Central
2. **Reduced Latency**: Faster Terraform operations due to regional proximity
3. **Data Residency Compliance**: All infrastructure data consolidated in France Central
4. **Simplified Disaster Recovery**: Single region for state and resources
5. **Cost Optimization**: Potential reduction in data transfer costs

### Migration Best Practices Learned

1. **Always Test Migration First**: Use development environment to validate process
2. **Backup Before Migration**: Keep old backend until new one is verified
3. **Update GitHub Secrets Immediately**: Prevents workflow failures
4. **Verify State Integrity**: Run terraform plan after migration to confirm state accuracy
5. **Document Resource Changes**: Update README.md and documentation with new backend details
6. **Clean Up Gradually**: Keep old backend for safety period before deletion

### Security Considerations

**Enhanced Security in New Backend:**
- **Versioning enabled**: State file history preserved for rollback scenarios
- **Blob public access disabled**: Enhanced security posture
- **TLS 1.2 minimum**: Modern encryption standards enforced
- **RBAC integration**: Better access control with Azure AD

### Operational Impact

**Post-Migration Improvements:**
- **Faster deployment times**: Reduced cross-region latency
- **Better monitoring**: All resources in same region for centralized monitoring
- **Simplified compliance**: Single region for audit and compliance requirements
- **Consistent resource naming**: Backend follows same regional naming convention

### Alternative Migration Strategies Considered

**Option 1: Fresh State (Not Chosen)**
- Delete old state and redeploy infrastructure
- **Pros**: Clean slate, no migration complexity
- **Cons**: Resource recreation, potential service disruption

**Option 2: State Import (Not Needed)**
- Export resources and import to new backend
- **Pros**: Granular control over migration
- **Cons**: Complex for large infrastructures

**Our Choice: Direct State Migration**
- **Pros**: Preserves resource history, minimal disruption, straightforward process
- **Cons**: Requires careful backup and verification steps

This migration successfully consolidated our Terraform state management with our application resources in France Central, improving performance and operational consistency across all environments.

## Next Steps for Learning

- Explore Terraform modules from the registry
- Learn about state locking and concurrent deployments
- Practice with different cloud providers
- Study advanced Terraform features (workspaces, remote state encryption)
- Implement automated testing for infrastructure code
- Research Azure RBAC best practices for automation accounts
- Investigate advanced DNS patterns (wildcard certificates, multiple domains)

## Static Identity and Resource Management for AKS-ACR Integration

### The Problem: Dynamic Resource IDs and Role Assignments

**Key Finding:** When using Terraform to manage both AKS clusters and ACR access, destroying and recreating infrastructure causes role assignment issues because resource IDs change.

**The Challenge:**
- AKS kubelet identity gets a new `principal_id` every time the cluster is recreated
- ACR resource ID changes if ACR is managed by the same Terraform state
- Admin needs to manually re-grant ACR access after every `terraform destroy/apply` cycle
- This breaks the "deploy once, works forever" principle

### Our Solution: Persistent Resource Groups with Developer-Created Resources

**Architecture Decision:**
- Separate persistent resources (ACR, identity) from ephemeral resources (AKS cluster)
- Developer manually creates persistent resources once using Azure CLI
- Admin only grants role assignments between the created resources
- Terraform references existing persistent resources instead of creating them

**Implementation:**

**Step 1: Developer Creates Persistent Resource Groups**
```bash
# Developer manually creates separate persistent resource groups per environment
az group create --name "walletwatch-dev-persistent-rg" --location "France Central" --subscription "<subscription-id>"
az group create --name "walletwatch-staging-persistent-rg" --location "West Europe" --subscription "<subscription-id>"
az group create --name "walletwatch-prod-persistent-rg" --location "West Europe" --subscription "<subscription-id>"
```

**Step 2: Developer Creates Static ACR**
```bash
# Developer manually creates ACR in persistent resource group (one-time per environment)
az acr create --name "walletwatchdevacr" --resource-group "walletwatch-dev-persistent-rg" --sku Basic --subscription "<subscription-id>"
```

**Step 3: Developer Creates Static Identities, Admin Grants Roles**
```bash
# Developer manually creates static user-assigned managed identities
az identity create --name "walletwatch-dev-aks-kubelet-identity" --resource-group "walletwatch-dev-persistent-rg" --subscription "<subscription-id>"
az identity create --name "walletwatch-dev-aks-controlplane-identity" --resource-group "walletwatch-dev-persistent-rg" --subscription "<subscription-id>"

# Admin performs one-time role assignments (survives infrastructure recreation)
az role assignment create \
  --assignee $(az identity show --name "walletwatch-dev-aks-kubelet-identity" --resource-group "walletwatch-dev-persistent-rg" --subscription "<subscription-id>" --query "principalId" --output tsv) \
  --role AcrPull \
  --scope $(az acr show --name "walletwatchdevacr" --resource-group "walletwatch-dev-persistent-rg" --subscription "<subscription-id>" --query "id" --output tsv) \
  --subscription "<subscription-id>"
```

**Step 4: Terraform References Existing Persistent Resources**
```hcl
# Reference existing User Assigned Managed Identity (manually created by developer)
data "azurerm_user_assigned_identity" "aks_kubelet" {
  name                = "${var.cluster_name}-kubelet-identity"
  resource_group_name = var.persistent_resource_group_name
}

# Reference existing ACR (manually created by developer)
# Role assignments are handled by admin outside of Terraform

# Configure AKS to use the persistent identity
resource "azurerm_kubernetes_cluster" "aks" {
  # ... other configuration

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.aks_kubelet.id]
  }

  kubelet_identity {
    client_id                 = data.azurerm_user_assigned_identity.aks_kubelet.client_id
    object_id                 = data.azurerm_user_assigned_identity.aks_kubelet.principal_id
    user_assigned_identity_id = data.azurerm_user_assigned_identity.aks_kubelet.id
  }
}
```

### Environment-Specific Configuration

**Terraform Variables per Environment:**
```hcl
# infrastructure/environments/dev/terraform.tfvars
persistent_resource_group_name = "walletwatch-dev-persistent-rg"

# infrastructure/environments/staging/terraform.tfvars
persistent_resource_group_name = "walletwatch-staging-persistent-rg"

# infrastructure/environments/prod/terraform.tfvars
persistent_resource_group_name = "walletwatch-prod-persistent-rg"
```

### Key Benefits of This Approach

1. **True Infrastructure Immutability**: AKS clusters can be destroyed/recreated without breaking ACR access
2. **Reduced Admin Overhead**: Role assignments happen once, not after every deployment
3. **Environment Isolation**: Each environment has its own persistent resources
4. **Cost Optimization**: Can destroy expensive compute resources (AKS) while keeping cheap storage resources (ACR)
5. **Security Compliance**: Admin controls persistent resources, developers control ephemeral ones

### Alternative Approaches Considered

**Option 1: System-Assigned Identity + Manual Attachment**
```bash
# After cluster creation, admin runs:
az aks update -n <cluster-name> -g <resource-group> --attach-acr <acr-name>
```
**Pros:** Azure handles role assignment automatically
**Cons:** Still requires manual step after every cluster recreation

**Option 2: Elevated Service Principal Permissions**
- Grant service principal "User Access Administrator" role
**Pros:** Fully automated role assignment
**Cons:** High security risk, often rejected by enterprises

### Operational Workflow

**Admin Initial Setup (Once per Environment):**
1. Create persistent resource group
2. Create ACR in persistent resource group
3. Create user-assigned managed identity in persistent resource group
4. Grant AcrPull role to identity for ACR scope

**Developer/CI/CD Operations (Repeatable):**
1. Run `terraform apply` to create AKS cluster with existing identity
2. Run `terraform destroy` to clean up temporary resources
3. ACR access works immediately on cluster recreation

### Key Lessons

1. **Separate concerns by lifecycle**: Persistent vs. ephemeral resources need different management strategies
2. **Resource group strategy matters**: Persistent resources need their own blast radius
3. **Static identities enable automation**: Pre-created identities with fixed principal IDs solve role assignment challenges
4. **Admin boundaries are good**: Clear separation between admin setup and developer operations
5. **Document the one-time setup**: Critical for team onboarding and disaster recovery

## AKS Control Plane Identity and Managed Identity Operator Permissions

### The Problem: CustomKubeletIdentityMissingPermissionError

**Key Finding:** When using separate user-assigned identities for AKS control plane and kubelet, the control plane identity needs "Managed Identity Operator" role on the kubelet identity.

**The Error:**
```
Error: creating Kubernetes Cluster: performing CreateOrUpdate: unexpected status 400 (400 Bad Request) with response: {
  "code": "CustomKubeletIdentityMissingPermissionError",
  "message": "The cluster using user-assigned managed identity must be granted 'Managed Identity Operator' role to assign kubelet identity..."
}
```

**Root Cause:**
- AKS control plane identity needs permission to manage (assign/unassign) the kubelet identity
- This is required when using user-assigned identities for both control plane and kubelet
- Without this permission, AKS cannot configure the kubelet to use the specified identity

### Our Solution: Separate Persistent User-Assigned Identities

**Architecture Decision:**
- Developer manually creates separate user-assigned identities for control plane and kubelet using Azure CLI
- Both identities are persistent (survive terraform destroy/redeploy cycles)
- Admin grants role assignment once between the created identities, persists across all deployments

**Implementation Steps:**

**Step 1: Developer Creates Control Plane Identity**
```bash
# Developer manually creates control plane identity in persistent resource group
az identity create \
  --name "walletwatch-dev-aks-controlplane-identity" \
  --resource-group "walletwatch-dev-persistent-rg" \
  --location "France Central"
```

**Step 2: Admin Grants Role Assignment (One-Time)**
```bash
# Grant control plane identity permission to manage kubelet identity
az role assignment create \
  --assignee <controlplane-identity-principal-id> \
  --role "Managed Identity Operator" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/walletwatch-dev-persistent-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/walletwatch-dev-aks-kubelet-identity"
```

**Step 3: Terraform References Both Identities**
```hcl
# Reference existing control plane identity
data "azurerm_user_assigned_identity" "aks_controlplane" {
  name                = "${var.cluster_name}-controlplane-identity"
  resource_group_name = var.persistent_resource_group_name
}

# Reference existing kubelet identity
data "azurerm_user_assigned_identity" "aks_kubelet" {
  name                = "${var.cluster_name}-kubelet-identity"
  resource_group_name = var.persistent_resource_group_name
}

# Configure AKS with separate identities
resource "azurerm_kubernetes_cluster" "aks" {
  # ... other configuration

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.aks_controlplane.id]
  }

  kubelet_identity {
    client_id                 = data.azurerm_user_assigned_identity.aks_kubelet.client_id
    object_id                 = data.azurerm_user_assigned_identity.aks_kubelet.principal_id
    user_assigned_identity_id = data.azurerm_user_assigned_identity.aks_kubelet.id
  }
}
```

### Complete Admin Setup Checklist

**For Each Environment (dev/staging/prod):**

1. **Developer creates persistent resource group:**
```bash
az group create --name "walletwatch-<env>-persistent-rg" --location "<location>"
```

2. **Developer creates kubelet identity (for ACR access):**
```bash
az identity create \
  --name "walletwatch-<env>-aks-kubelet-identity" \
  --resource-group "walletwatch-<env>-persistent-rg"
```

3. **Developer creates control plane identity:**
```bash
az identity create \
  --name "walletwatch-<env>-aks-controlplane-identity" \
  --resource-group "walletwatch-<env>-persistent-rg"
```

4. **Developer creates ACR:**
```bash
az acr create \
  --name "walletwatch<env>acr" \
  --resource-group "walletwatch-<env>-persistent-rg" \
  --sku <Basic|Standard|Premium>
```

5. **Grant ACR access to kubelet identity:**
```bash
az role assignment create \
  --assignee <kubelet-identity-principal-id> \
  --role "AcrPull" \
  --scope <acr-resource-id>
```

6. **Grant Managed Identity Operator to control plane:**
```bash
az role assignment create \
  --assignee <controlplane-identity-principal-id> \
  --role "Managed Identity Operator" \
  --scope <kubelet-identity-resource-id>
```

7. **Developer creates Key Vault:**
```bash
az keyvault create \
  --name "walletwatch-<env>-kv" \
  --resource-group "walletwatch-<env>-persistent-rg" \
  --enable-rbac-authorization true
```

8. **Grant Key Vault access to kubelet identity (if using Key Vault):**
```bash
az role assignment create \
  --assignee <kubelet-identity-principal-id> \
  --role "Key Vault Secrets User" \
  --scope <keyvault-resource-id>
```

9. **Grant Network access to AKS cluster identity (for LoadBalancer services):**
```bash
az role assignment create \
  --assignee <aks-cluster-identity-principal-id> \
  --role "Network Contributor" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/walletwatch-<env>-rg"
```

### Role Assignment Summary

**Required Role Assignments (Per Environment):**
1. **Kubelet Identity → ACR**: "AcrPull" role (for container image access)
2. **Control Plane Identity → Kubelet Identity**: "Managed Identity Operator" role (for AKS cluster creation)
3. **Kubelet Identity → Key Vault**: "Key Vault Secrets User" role (optional, for secrets access)
4. **AKS Cluster Identity → Resource Group**: "Network Contributor" role (for LoadBalancer public IP access)
   - Enables LoadBalancer services to access and assign Azure public IPs
   - Required for NGINX ingress controller external IP assignment
   - Prevents "AuthorizationFailed" errors when creating LoadBalancer services

### Alternative Approaches Considered

**Option 1: Use Same Identity for Both Control Plane and Kubelet**
- Identity needs permission to manage itself
- Simpler setup but architecturally less clean
- Still requires admin role assignment

**Option 2: System-Assigned Identity for Control Plane**
- Control plane gets new identity every deployment
- Requires admin to re-grant permissions after every terraform apply
- Not suitable for frequent deployment cycles

**Option 3: Elevated Service Principal Permissions**
- Grant service principal "User Access Administrator" role
- Fully automated but high security risk
- Often rejected by enterprise security policies

### Key Benefits of Our Approach

1. **No Role Assignment Needed After Deployments**: All permissions are persistent
2. **Clean Separation of Concerns**: Control plane and kubelet have separate identities
3. **Environment Isolation**: Each environment has independent identity setup
4. **Security Compliance**: Minimal permissions following principle of least privilege
5. **Terraform Destroy Safety**: All role assignments survive infrastructure recreation

### Integration with Key Vault

**When using Azure Key Vault integration:**
- Kubelet identity needs "Key Vault Secrets User" role on Key Vault
- Key Vault should be created in persistent resource group
- Role assignment persists through terraform destroy/redeploy cycles
- No additional AKS configuration needed beyond standard identity setup

### Troubleshooting

**Common Issues:**
1. **Wrong identity used**: Ensure control plane identity has the role, not kubelet identity
2. **Scope mismatch**: Role assignment scope must be the kubelet identity resource ID
3. **Principal ID vs Client ID confusion**: Use principal_id for role assignments, client_id for AKS configuration
4. **Resource not found**: Ensure all identities exist in persistent resource group before terraform apply

**Verification Commands:**
```bash
# Check role assignments on kubelet identity
az role assignment list --assignee <kubelet-identity-principal-id>

# Check role assignments on control plane identity
az role assignment list --assignee <controlplane-identity-principal-id>

# Verify identity exists
az identity show --name "<identity-name>" --resource-group "<persistent-rg>"
```

## Infrastructure Architecture Refactoring for Cost Efficiency

### Problem: High Cost of Persistent Resources

**Initial Architecture Challenge:**
- ACR and Key Vault were manually created in persistent resource groups
- These resources remained running 24/7 even when not needed
- Cost accumulated during development and testing phases
- Terraform couldn't manage lifecycle of these critical resources

**Cost Impact:**
- ACR: Continuous billing even when clusters are stopped
- Key Vault: Always-on pricing regardless of usage
- Manual resource management overhead
- Difficult to implement cost-saving schedules

### Solution: Move ACR and Key Vault to Terraform-Managed Resource Groups

**Architecture Evolution (December 2024):**

**Before Refactoring:**
```
Persistent RG (walletwatch-dev-persistent-rg):
├── Control Plane Identity (manual)
├── Kubelet Identity (manual)
├── ACR (manual) ← Always running, cost accumulating
└── Key Vault (manual) ← Always running, cost accumulating

Main RG (walletwatch-dev-rg):
├── AKS (terraform)
├── PostgreSQL (terraform)
└── Other compute resources (terraform)
```

**After Refactoring:**
```
Persistent RG (walletwatch-dev-persistent-rg):
├── Control Plane Identity (manual) ← Only identities remain
└── Kubelet Identity (manual) ← Minimal cost

Main RG (walletwatch-dev-rg):
├── AKS (terraform)
├── PostgreSQL (terraform)
├── ACR (terraform) ← Now managed by terraform!
├── Key Vault (terraform) ← Now managed by terraform!
└── Other compute resources (terraform)
```

### Implementation Steps

**Step 1: Create New Terraform Modules**

1. **ACR Module** (`infrastructure/modules/acr/`):
```hcl
resource "azurerm_container_registry" "main" {
  name                = "walletwatch${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  # ... additional configuration
}
```

2. **Key Vault Module** (`infrastructure/modules/keyvault/`):
```hcl
resource "azurerm_key_vault" "main" {
  name                = "walletwatch-${var.environment}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name
  enable_rbac_authorization = var.enable_rbac_authorization
  # ... additional configuration
}
```

**Step 2: Update Role Assignment Strategy**

**Old Approach (Resource-Level Permissions):**
```bash
# Kubelet → ACR (specific resource)
az role assignment create \
  --assignee <kubelet-identity> \
  --role "AcrPull" \
  --scope "/subscriptions/<id>/resourceGroups/walletwatch-dev-persistent-rg/providers/Microsoft.ContainerRegistry/registries/walletwatch<env>acr"

# Kubelet → Key Vault (specific resource)
az role assignment create \
  --assignee <kubelet-identity> \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/<id>/resourceGroups/walletwatch-dev-persistent-rg/providers/Microsoft.KeyVault/vaults/walletwatch-dev-kv"
```

**New Approach (Resource Group-Level Permissions):**
```bash
# Kubelet → Resource Group (covers all ACRs and Key Vaults)
az role assignment create \
  --assignee ea161ec0-3fb0-4d81-8323-3b969bd3cc28 \
  --role "AcrPull" \
  --scope "/subscriptions/56637f11-5e83-404d-b6b3-04c7dab01412/resourceGroups/walletwatch-dev-rg"

az role assignment create \
  --assignee ea161ec0-3fb0-4d81-8323-3b969bd3cc28 \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/56637f11-5e83-404d-b6b3-04c7dab01412/resourceGroups/walletwatch-dev-rg"

# Service Principal → Resource Group (for managing secrets)
az role assignment create \
  --assignee c408673e-9548-47fa-b2ba-c15194d75375 \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/56637f11-5e83-404d-b6b3-04c7dab01412/resourceGroups/walletwatch-dev-rg"

# User → Resource Group (for manual management)
az role assignment create \
  --assignee cf71b9f7-6567-4438-a705-e7ff9aa623ea \
  --role "Key Vault Secrets Officer" \
  --scope "/subscriptions/56637f11-5e83-404d-b6b3-04c7dab01412/resourceGroups/walletwatch-dev-rg"

# CRITICAL: Control Plane → Kubelet Identity (still specific resource)
az role assignment create \
  --assignee fa229838-37ee-454c-a3f6-d9b14130d90a \
  --role "Managed Identity Operator" \
  --scope "/subscriptions/56637f11-5e83-404d-b6b3-04c7dab01412/resourceGroups/walletwatch-dev-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/walletwatch-dev-aks-kubelet-identity"
```

**Step 3: Update Environment Configurations**

Add ACR and Key Vault variables to environment configs:

```hcl
# Dev Environment (cost-optimized)
acr_sku = "Basic"
keyvault_sku_name = "standard"
keyvault_enable_rbac_authorization = true
keyvault_soft_delete_retention_days = 7
keyvault_purge_protection_enabled = false

# Production Environment (security-focused)
acr_sku = "Premium"
keyvault_sku_name = "premium"
keyvault_enable_rbac_authorization = true
keyvault_soft_delete_retention_days = 90
keyvault_purge_protection_enabled = true
keyvault_network_acls_default_action = "Deny"
```

**Step 4: Update Module Dependencies**

```hcl
# Key Vault Secrets now references Terraform-managed Key Vault
module "keyvault_secrets" {
  source = "./modules/keyvault-secrets"

  environment         = var.environment
  resource_group_name = module.resource_group.name
  keyvault_id         = module.keyvault.id  # ← Changed from data source
  # ... other configuration

  depends_on = [module.postgresql, module.keyvault]
}
```

### Cost Benefits Achieved

**1. Terraform Destroy Saves Costs:**
```bash
# Before: Manual resources stay running 24/7
terraform destroy  # Only destroys AKS/PostgreSQL, ACR/KV remain running

# After: All resources destroyed together
terraform destroy  # Destroys AKS/PostgreSQL/ACR/KeyVault = $0 overnight!
```

**2. Automated Cleanup with GitHub Actions:**
```yaml
# Scheduled cleanup saves costs automatically
- name: Destroy Dev Environment
  uses: ./.github/workflows/scheduled-destroy-infrastructure.yml
  schedule:
    - cron: '0 20 * * *'  # 8 PM UTC = automatic cost savings
```

**3. Environment-Specific Resource Sizing:**
- **Dev**: Basic ACR ($5/month vs $20/month Standard)
- **Staging**: Standard ACR for testing
- **Production**: Premium ACR with georeplications only when needed

### Security Maintained

**Role Assignment Persistence:**
- ✅ Identity role assignments survive terraform destroy/redeploy
- ✅ Resource group-level permissions work for new resources
- ✅ Principle of least privilege maintained
- ✅ RBAC authorization enabled for Key Vault

**Network Security Enhanced:**
- **Dev**: Open access for development ease
- **Production**: Network ACLs with IP restrictions
- **Key Vault**: RBAC instead of access policies

### Migration Process

**For Existing Environments:**

1. **Update role assignments** to resource group level (see commands above)
2. **Import existing resources** into Terraform state:
```bash
# Import existing ACR
terraform import module.acr.azurerm_container_registry.main /subscriptions/<id>/resourceGroups/walletwatch-dev-rg/providers/Microsoft.ContainerRegistry/registries/walletwatch<env>acr

# Import existing Key Vault
terraform import module.keyvault.azurerm_key_vault.main /subscriptions/<id>/resourceGroups/walletwatch-dev-rg/providers/Microsoft.KeyVault/vaults/walletwatch-dev-kv
```
3. **Apply Terraform** to bring resources under management
4. **Test deployment** to ensure role assignments work correctly

### Key Learnings

**1. Resource Group-Level Permissions Scale Better:**
- Single role assignment covers multiple resources
- New resources automatically inherit permissions
- Easier to manage across environments

**2. Cost Efficiency vs Operational Complexity:**
- Terraform-managed resources = better cost control
- Trade-off: More complex import/migration process
- Benefit: Automated cost savings through destroy/recreate cycles

**3. Identity Persistence Strategy:**
- Keep identities in persistent RG (low cost, high persistence value)
- Move high-cost resources to Terraform management
- Balance between automation and persistence

**4. Environment-Specific Configuration:**
- Dev: Cost-optimized, open access
- Staging: Balanced cost and security
- Production: Security-first, controlled access

This refactoring demonstrates how Infrastructure as Code can evolve to meet changing business requirements while maintaining security and operational excellence.