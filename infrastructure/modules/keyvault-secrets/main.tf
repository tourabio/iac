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

# JWT Key (RSA-2048 for signing and verification)
resource "azurerm_key_vault_key" "jwt_signing_key" {
  name         = "jwt-signing-key"
  key_vault_id = var.keyvault_id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "sign",
    "verify"
  ]

  tags = var.tags
}