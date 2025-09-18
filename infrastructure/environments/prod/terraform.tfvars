# Production Environment Configuration
environment         = "prod"
resource_group_name = "walletwatch-prod-rg"
location            = "West Europe"
acr_name            = "walletwatchprodacr"
acr_sku             = "Standard"
acr_admin_enabled   = false

# AKS Configuration - Production Environment
aks_cluster_name        = "walletwatch-prod-aks"
aks_node_count          = 1                    # Start with single worker node
aks_vm_size             = "Standard_B2s"       # Cost-effective size
kubernetes_version      = "1.28.3"
aks_enable_auto_scaling = true
aks_min_nodes           = 1
aks_max_nodes           = 3

# Persistent resources (pre-created by admin)
persistent_resource_group_name = "walletwatch-prod-persistent-rg"