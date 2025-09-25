output "name" {
  description = "Name of the resource group"
  value       = data.azurerm_resource_group.default.name
}

output "location" {
  description = "Location of the resource group"
  value       = data.azurerm_resource_group.default.location
}

output "id" {
  description = "ID of the resource group"
  value       = data.azurerm_resource_group.default.id
}