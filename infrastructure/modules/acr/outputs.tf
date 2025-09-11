output "name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "id" {
  description = "ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}

output "admin_username" {
  description = "Admin username for the ACR (if admin is enabled)"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "Admin password for the ACR (if admin is enabled)"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}