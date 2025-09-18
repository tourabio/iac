# Development Environment Configuration
environment         = "dev"
resource_group_name = "walletwatch-dev-rg"
location            = "France Central"
acr_name            = "walletwatchdevacr"
acr_sku             = "Basic"
acr_admin_enabled   = false

# AKS Configuration - Dev Environment
aks_cluster_name        = "walletwatch-dev-aks"
aks_node_count          = 1                    # Single worker node
aks_vm_size             = "Standard_B2s"       # Cost-effective: 2 vCPU, 4GB RAM
kubernetes_version      = "1.31.10"
aks_enable_auto_scaling = true
aks_min_nodes           = 1
aks_max_nodes           = 2

# Using free Azure domain - no configuration needed

# Persistent resources (pre-created by admin)
persistent_resource_group_name = "walletwatch-dev-persistent-rg"