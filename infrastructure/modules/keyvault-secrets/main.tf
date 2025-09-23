data "azurerm_key_vault" "main" {
  name                = "walletwatch-${var.environment}-kv"
  resource_group_name = var.persistent_resource_group_name
}

resource "azurerm_key_vault_secret" "database_host" {
  name         = "database-host"
  value        = var.database_host
  key_vault_id = data.azurerm_key_vault.main.id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "database_port" {
  name         = "database-port"
  value        = var.database_port
  key_vault_id = data.azurerm_key_vault.main.id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "database_name" {
  name         = "database-name"
  value        = var.database_name
  key_vault_id = data.azurerm_key_vault.main.id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "database_username" {
  name         = "database-username"
  value        = var.database_username
  key_vault_id = data.azurerm_key_vault.main.id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "database_password" {
  name         = "database-password"
  value        = var.database_password
  key_vault_id = data.azurerm_key_vault.main.id
  tags         = var.tags
}