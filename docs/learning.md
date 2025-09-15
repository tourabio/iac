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
│   ├── acr/          # Azure Container Registry
│   ├── aks/          # Azure Kubernetes Service
│   ├── dns/          # DNS Zone and Records
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

### Two-Phase Deployment Strategy

**Phase 1: Infrastructure First**
- Deploy AKS cluster, ACR, DNS zone
- Set `create_dns_records = false`
- Outputs DNS nameservers for domain delegation

**Phase 2: Services and DNS Records**
- Deploy ArgoCD/NGINX via GitOps workflow
- Set `create_dns_records = true`
- Terraform reads LoadBalancer IP and creates DNS records

### Key Architecture Decisions

**Modular DNS Module:**
```
modules/dns/
├── main.tf      # DNS zone and records
├── variables.tf # Configuration options
└── outputs.tf   # Nameservers and FQDNs
```

**Environment-Specific Domains:**
- Dev: `argocd-dev.walletwatch.com`
- Staging: `argocd-staging.walletwatch.com`
- Prod: `argocd-prod.walletwatch.com`

**Conditional Resource Creation:**
- Use `count` parameter to control when DNS records are created
- Prevents chicken-and-egg problem with LoadBalancer dependencies

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
      - argocd-dev.walletwatch.com
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
```

### Key Lessons

1. **Infrastructure dependencies matter** - DNS must exist before services can use it
2. **Terraform data sources are powerful** - Read live Kubernetes state
3. **Conditional resources solve timing issues** - Use `count` for optional resources
4. **Domain ownership is required** - You must control the domain's nameservers
5. **Two-phase deployment works** - Split infrastructure and application concerns
6. **SSL automation requires proper DNS** - Let's Encrypt needs resolvable domains

### Operational Considerations

**Domain Delegation Required:**
- Configure domain registrar to use Azure DNS nameservers
- Propagation can take 24-48 hours
- Test with `nslookup` or `dig` commands

**Cost Implications:**
- Azure DNS zone: ~$0.50/month per zone
- DNS queries: $0.40 per million queries
- Much cheaper than manual management overhead

## Next Steps for Learning

- Explore Terraform modules from the registry
- Learn about state locking and concurrent deployments
- Practice with different cloud providers
- Study advanced Terraform features (workspaces, remote state encryption)
- Implement automated testing for infrastructure code
- Research Azure RBAC best practices for automation accounts
- Investigate advanced DNS patterns (wildcard certificates, multiple domains)