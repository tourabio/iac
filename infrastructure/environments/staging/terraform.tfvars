# Staging Environment Configuration
environment         = "staging"
resource_group_name = "walletwatch-staging-rg"
location            = "France Central"

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

# ACR Configuration - Staging Environment
acr_sku           = "Standard"           # Standard tier for staging
acr_admin_enabled = false                # Use managed identities

# Key Vault Configuration - Staging Environment
keyvault_sku_name                      = "standard"   # Standard tier
keyvault_enabled_for_disk_encryption   = false        # Not needed for staging
keyvault_enabled_for_deployment        = false        # Not needed for staging
keyvault_enabled_for_template_deployment = false      # Not needed for staging
keyvault_enable_rbac_authorization     = true         # Use RBAC for access control
keyvault_soft_delete_retention_days    = 14           # Extended retention for staging
keyvault_purge_protection_enabled      = false        # Not needed for staging
keyvault_network_acls_default_action   = "Allow"      # Allow all traffic for staging
keyvault_network_acls_bypass           = "AzureServices"
keyvault_network_acls_ip_rules         = []

# PostgreSQL Configuration - Staging Environment
postgresql_version               = "16"
postgresql_admin_username        = "walletwatch_admin"
postgresql_database_name         = "walletwatch"
postgresql_sku_name             = "B_Standard_B2s"      # Basic tier: 2 vCore, 4GB RAM
postgresql_storage_mb           = 65536                 # 64GB
postgresql_backup_retention_days = 14                  # Extended retention for staging
postgresql_availability_zone    = "1"