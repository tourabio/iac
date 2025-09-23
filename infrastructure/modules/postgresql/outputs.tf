output "server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "server_fqdn" {
  description = "Fully qualified domain name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "server_id" {
  description = "ID of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.main.id
}

output "database_name" {
  description = "Name of the created database"
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "admin_username" {
  description = "Administrator username"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "admin_password" {
  description = "Administrator password for Key Vault storage"
  value       = random_password.db_password.result
  sensitive   = true
}