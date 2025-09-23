# Development Environment Configuration
environment         = "dev"
resource_group_name = "walletwatch-dev-rg"
location            = "France Central"

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

# PostgreSQL Configuration - Dev Environment (cost-optimized)
postgresql_version               = "16"
postgresql_admin_username        = "walletwatch_admin"
postgresql_database_name         = "walletwatch"
postgresql_sku_name             = "B_Standard_B1ms"     # Basic tier: 1 vCore, 2GB RAM
postgresql_storage_mb           = 32768                 # 32GB minimum
postgresql_backup_retention_days = 7                   # Minimum retention
postgresql_availability_zone    = "1"