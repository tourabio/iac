# Production Environment Configuration
environment         = "prod"
resource_group_name = "walletwatch-prod-rg"
location            = "France Central"

# AKS Configuration - Production Environment
aks_cluster_name        = "walletwatch-prod-aks"
aks_node_count          = 1                    # Start with single worker node
aks_vm_size             = "Standard_B2s"       # Cost-effective size
kubernetes_version      = "1.31.10"
aks_enable_auto_scaling = true
aks_min_nodes           = 1
aks_max_nodes           = 3

# Persistent resources (pre-created by admin)
persistent_resource_group_name = "walletwatch-prod-persistent-rg"

# PostgreSQL Configuration - Production Environment
postgresql_version               = "16"
postgresql_admin_username        = "walletwatch_admin"
postgresql_database_name         = "walletwatch"
postgresql_sku_name             = "B_Standard_B2s"      # Basic tier: 2 vCore, 4GB RAM
postgresql_storage_mb           = 65536                 # 64GB
postgresql_backup_retention_days = 30                  # Extended retention for production
postgresql_availability_zone    = "1"