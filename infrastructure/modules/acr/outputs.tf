output "id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

output "name" {
  description = "The name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "login_server" {
  description = "The login server of the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "The admin username of the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "admin_password" {
  description = "The admin password of the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "resource_group_name" {
  description = "The resource group name of the Azure Container Registry"
  value       = azurerm_container_registry.main.resource_group_name
}