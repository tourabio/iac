data "azurerm_client_config" "current" {}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "walletwatch-${var.environment}-postgres"
  resource_group_name = var.resource_group_name
  location            = var.location
  version             = var.postgresql_version

  administrator_login    = var.admin_username
  administrator_password = random_password.db_password.result

  backup_retention_days = var.backup_retention_days
  geo_redundant_backup_enabled = var.geo_redundant_backup_enabled

  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  zone = var.availability_zone

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allowed_ip_1" {
  name             = "AllowedIP1"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "196.203.109.254"
  end_ip_address   = "196.203.109.254"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allowed_ip_2" {
  name             = "AllowedIP2"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "172.27.244.23"
  end_ip_address   = "172.27.244.23"
}