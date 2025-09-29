output "id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "resource_group_name" {
  description = "The resource group name of the Key Vault"
  value       = azurerm_key_vault.main.resource_group_name
}

output "tenant_id" {
  description = "The tenant ID of the Key Vault"
  value       = azurerm_key_vault.main.tenant_id
}