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