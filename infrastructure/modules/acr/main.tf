resource "azurerm_container_registry" "main" {
  name                = "walletwatch${var.environment}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  # Enable georeplications for higher SKUs if specified
  dynamic "georeplications" {
    for_each = var.georeplications
    content {
      location                = georeplications.value.location
      zone_redundancy_enabled = georeplications.value.zone_redundancy_enabled
    }
  }

  # Network access rules for enhanced security (only for Premium SKU)
  dynamic "network_rule_set" {
    for_each = var.network_rule_set_enabled && var.sku == "Premium" ? [1] : []
    content {
      default_action = var.network_rule_default_action

      dynamic "ip_rule" {
        for_each = var.network_rule_ip_ranges
        iterator = ip
        content {
          action   = "Allow"
          ip_range = ip.value
        }
      }
    }
  }

  tags = var.tags
}