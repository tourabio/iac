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

# ACR Configuration - Production Environment
acr_sku                         = "Premium"            # Premium tier for production
acr_admin_enabled               = false                # Use managed identities
acr_network_rule_set_enabled    = true                # Restrict network access for production
acr_network_rule_default_action = "Deny"              # Deny by default, allow specific IPs
acr_network_rule_ip_ranges      = []                  # Add specific IP ranges as needed
acr_georeplications             = []                  # Configure georeplications as needed

# Key Vault Configuration - Production Environment
keyvault_sku_name                      = "premium"    # Premium tier for production
keyvault_enabled_for_disk_encryption   = true         # Enable for production security
keyvault_enabled_for_deployment        = true         # Enable for VM deployments
keyvault_enabled_for_template_deployment = true       # Enable for ARM templates
keyvault_enable_rbac_authorization     = true         # Use RBAC for access control
keyvault_soft_delete_retention_days    = 90           # Maximum retention for production
keyvault_purge_protection_enabled      = true         # Enable purge protection for production
keyvault_network_acls_default_action   = "Deny"       # Restrict network access for production
keyvault_network_acls_bypass           = "AzureServices"
keyvault_network_acls_ip_rules         = []           # Add specific IP ranges as needed

# PostgreSQL Configuration - Production Environment
postgresql_version               = "16"
postgresql_admin_username        = "walletwatch_admin"
postgresql_database_name         = "walletwatch"
postgresql_sku_name             = "B_Standard_B2s"      # Basic tier: 2 vCore, 4GB RAM
postgresql_storage_mb           = 65536                 # 64GB
postgresql_backup_retention_days = 30                  # Extended retention for production
postgresql_availability_zone    = "1"