output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = data.azurerm_key_vault.main.id
}

output "secret_names" {
  description = "Names of the created secrets"
  value = [
    azurerm_key_vault_secret.database_host.name,
    azurerm_key_vault_secret.database_port.name,
    azurerm_key_vault_secret.database_name.name,
    azurerm_key_vault_secret.database_username.name,
    azurerm_key_vault_secret.database_password.name
  ]
}