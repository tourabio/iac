# Public IP with DNS label for free domain-like access
resource "azurerm_public_ip" "main" {
  name                = "${var.environment}-argocd-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  # This creates: argocd-dev-walletwatch.francecentral.cloudapp.azure.com
  domain_name_label   = "argocd-${var.environment}-walletwatch"

  tags = var.tags
}

# Output the free Azure domain
locals {
  azure_domain = "${azurerm_public_ip.main.domain_name_label}.${var.location}.cloudapp.azure.com"
}