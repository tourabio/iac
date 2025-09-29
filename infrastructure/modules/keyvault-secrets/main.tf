resource "azurerm_key_vault_secret" "database_host" {
  name         = "database-host"
  value        = var.database_host
  key_vault_id = var.keyvault_id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "database_port" {
  name         = "database-port"
  value        = var.database_port
  key_vault_id = var.keyvault_id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "database_name" {
  name         = "database-name"
  value        = var.database_name
  key_vault_id = var.keyvault_id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "database_username" {
  name         = "database-username"
  value        = var.database_username
  key_vault_id = var.keyvault_id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "database_password" {
  name         = "database-password"
  value        = var.database_password
  key_vault_id = var.keyvault_id
  tags         = var.tags
}

# Flyway Secrets
resource "azurerm_key_vault_secret" "flyway_connect_user" {
  name         = "flyway-connect-user"
  value        = var.flyway_connect_user
  key_vault_id = var.keyvault_id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "flyway_connect_user_password" {
  name         = "flyway-connect-user-password"
  value        = var.flyway_connect_user_password
  key_vault_id = var.keyvault_id
  tags         = var.tags
}

# JWT Secrets
resource "azurerm_key_vault_secret" "jwt_public_key" {
  name         = "jwt-public-key"
  value        = var.jwt_public_key
  key_vault_id = var.keyvault_id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "jwt_private_key" {
  name         = "jwt-private-key"
  value        = var.jwt_private_key
  key_vault_id = var.keyvault_id
  tags         = var.tags
}