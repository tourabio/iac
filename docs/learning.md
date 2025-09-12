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

## Next Steps for Learning

- Explore Terraform modules from the registry
- Learn about state locking and concurrent deployments
- Practice with different cloud providers
- Study advanced Terraform features (workspaces, remote state encryption)
- Implement automated testing for infrastructure code