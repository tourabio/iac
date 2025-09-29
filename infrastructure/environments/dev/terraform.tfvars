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

# ACR Configuration - Dev Environment
acr_sku           = "Basic"              # Basic tier for dev
acr_admin_enabled = false                # Use managed identities

# Key Vault Configuration - Dev Environment
keyvault_sku_name                      = "standard"   # Standard tier
keyvault_enabled_for_disk_encryption   = false        # Not needed for dev
keyvault_enabled_for_deployment        = false        # Not needed for dev
keyvault_enabled_for_template_deployment = false      # Not needed for dev
keyvault_enable_rbac_authorization     = true         # Use RBAC for access control
keyvault_soft_delete_retention_days    = 7            # Minimum retention for dev
keyvault_purge_protection_enabled      = false        # Not needed for dev
keyvault_network_acls_default_action   = "Allow"      # Allow all traffic for dev
keyvault_network_acls_bypass           = "AzureServices"
keyvault_network_acls_ip_rules         = []

# PostgreSQL Configuration - Dev Environment (cost-optimized)
postgresql_version               = "16"
postgresql_admin_username        = "walletwatch_admin"
postgresql_database_name         = "walletwatch"
postgresql_sku_name             = "B_Standard_B1ms"     # Basic tier: 1 vCore, 2GB RAM
postgresql_storage_mb           = 32768                 # 32GB minimum
postgresql_backup_retention_days = 7                   # Minimum retention
postgresql_availability_zone    = "1"