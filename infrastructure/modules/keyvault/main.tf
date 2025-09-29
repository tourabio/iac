# Get current client configuration for default access policy
data "azurerm_client_config" "current" {}

# Reference the kubelet identity from persistent RG for access policy
data "azurerm_user_assigned_identity" "aks_kubelet" {
  name                = "walletwatch-${var.environment}-aks-kubelet-identity"
  resource_group_name = var.persistent_resource_group_name
}

resource "azurerm_key_vault" "main" {
  name                = "walletwatch-${var.environment}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.sku_name

  # Security settings
  enabled_for_disk_encryption     = var.enabled_for_disk_encryption
  enabled_for_deployment          = var.enabled_for_deployment
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization       = var.enable_rbac_authorization
  soft_delete_retention_days      = var.soft_delete_retention_days
  purge_protection_enabled        = var.purge_protection_enabled

  # Network access rules
  network_acls {
    default_action = var.network_acls_default_action
    bypass         = var.network_acls_bypass
    ip_rules       = var.network_acls_ip_rules
  }

  tags = var.tags
}

# Access policy for the service principal (if RBAC is not used)
resource "azurerm_key_vault_access_policy" "service_principal" {
  count        = var.enable_rbac_authorization ? 0 : 1
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge"
  ]
}

# Access policy for the kubelet identity (if RBAC is not used)
resource "azurerm_key_vault_access_policy" "kubelet_identity" {
  count        = var.enable_rbac_authorization ? 0 : 1
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_user_assigned_identity.aks_kubelet.principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}