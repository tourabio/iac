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

**Our Solutions:**

**Option 1: Remove Role Assignment from Terraform**
```hcl
# Instead of automated role assignment in Terraform:
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope               = var.acr_id
}

# Use manual attachment after deployment:
# az aks update -n <cluster-name> -g <resource-group> --attach-acr <acr-name>
```

**Option 2: Use System-Assigned Managed Identity**
- AKS already uses `identity { type = "SystemAssigned" }`
- Azure handles permissions automatically when using `az aks update --attach-acr`
- No need for explicit role assignment resources

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

### Our Solution: Persistent Resource Groups with Pre-Created Resources

**Architecture Decision:**
- Separate persistent resources (ACR, identity) from ephemeral resources (AKS cluster)
- Admin creates resources once in persistent resource groups
- Terraform references existing resources instead of creating them

**Implementation:**

**Step 1: Persistent Resource Group Strategy**
```bash
# Admin creates separate persistent resource groups per environment
az group create --name "walletwatch-dev-persistent-rg" --location "France Central" --subscription "<subscription-id>"
az group create --name "walletwatch-staging-persistent-rg" --location "West Europe" --subscription "<subscription-id>"
az group create --name "walletwatch-prod-persistent-rg" --location "West Europe" --subscription "<subscription-id>"
```

**Step 2: Static ACR Creation**
```bash
# Create ACR in persistent resource group (one-time per environment)
az acr create --name "walletwatchdevacr" --resource-group "walletwatch-dev-persistent-rg" --sku Basic --subscription "<subscription-id>"
```

**Step 3: Static Identity Creation and Role Assignment**
```bash
# Create static user-assigned managed identity
az identity create --name "walletwatch-dev-aks-kubelet-identity" --resource-group "walletwatch-dev-persistent-rg" --subscription "<subscription-id>"

# One-time role assignment (survives infrastructure recreation)
az role assignment create \
  --assignee $(az identity show --name "walletwatch-dev-aks-kubelet-identity" --resource-group "walletwatch-dev-persistent-rg" --subscription "<subscription-id>" --query "principalId" --output tsv) \
  --role AcrPull \
  --scope $(az acr show --name "walletwatchdevacr" --resource-group "walletwatch-dev-persistent-rg" --subscription "<subscription-id>" --query "id" --output tsv) \
  --subscription "<subscription-id>"
```

**Step 4: Terraform References Existing Resources**
```hcl
# Reference existing User Assigned Managed Identity
data "azurerm_user_assigned_identity" "aks_kubelet" {
  name                = "${var.cluster_name}-kubelet-identity"
  resource_group_name = var.persistent_resource_group_name
}

# ACR integration is handled outside of Terraform
# AcrPull role assignment is done manually by admin

# Configure AKS to use the static identity
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
- Create separate user-assigned identities for control plane and kubelet
- Both identities are persistent (survive terraform destroy/redeploy cycles)
- Admin grants role assignment once, persists across all deployments

**Implementation Steps:**

**Step 1: Admin Creates Control Plane Identity**
```bash
# Create control plane identity in persistent resource group
az identity create \
  --name "walletwatch-dev-aks-controlplane-identity" \
  --resource-group "walletwatch-dev-persistent-rg" \
  --location "France Central"
```

**Step 2: Admin Creates Role Assignment (One-Time)**
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

1. **Create persistent resource group:**
```bash
az group create --name "walletwatch-<env>-persistent-rg" --location "<location>"
```

2. **Create kubelet identity (for ACR access):**
```bash
az identity create \
  --name "walletwatch-<env>-aks-kubelet-identity" \
  --resource-group "walletwatch-<env>-persistent-rg"
```

3. **Create control plane identity:**
```bash
az identity create \
  --name "walletwatch-<env>-aks-controlplane-identity" \
  --resource-group "walletwatch-<env>-persistent-rg"
```

4. **Create ACR (if not exists):**
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

7. **Create Key Vault (optional):**
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