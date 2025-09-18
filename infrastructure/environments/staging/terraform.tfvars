# Staging Environment Configuration
environment         = "staging"
resource_group_name = "walletwatch-staging-rg"
location            = "West Europe"
acr_name            = "walletwatchstagingacr"
acr_sku             = "Basic"
acr_admin_enabled   = false

# AKS Configuration - Staging Environment
aks_cluster_name        = "walletwatch-staging-aks"
aks_node_count          = 1                    # Single worker node
aks_vm_size             = "Standard_B2s"       # Cost-effective size
kubernetes_version      = "1.31.10"
aks_enable_auto_scaling = true
aks_min_nodes           = 1
aks_max_nodes           = 2

# Persistent resources (pre-created by admin)
persistent_resource_group_name = "walletwatch-staging-persistent-rg"