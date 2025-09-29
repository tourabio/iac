output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = var.keyvault_id
}

output "secret_names" {
  description = "Names of the created secrets"
  value = [
    azurerm_key_vault_secret.database_host.name,
    azurerm_key_vault_secret.database_port.name,
    azurerm_key_vault_secret.database_name.name,
    azurerm_key_vault_secret.database_username.name,
    azurerm_key_vault_secret.database_password.name,
    azurerm_key_vault_secret.flyway_connect_user.name,
    azurerm_key_vault_secret.flyway_connect_user_password.name
  ]
}

output "jwt_key_name" {
  description = "Name of the JWT signing key"
  value       = azurerm_key_vault_key.jwt_signing_key.name
}

output "jwt_key_id" {
  description = "ID of the JWT signing key"
  value       = azurerm_key_vault_key.jwt_signing_key.id
}