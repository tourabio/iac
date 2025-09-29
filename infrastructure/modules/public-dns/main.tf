# Public IP for ArgoCD with DNS label for free domain-like access
resource "azurerm_public_ip" "argocd" {
  name                = "${var.environment}-argocd-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  # This creates: argocd-dev-walletwatch.francecentral.cloudapp.azure.com
  domain_name_label   = "argocd-${var.environment}-walletwatch"

  tags = var.tags


  lifecycle {
    prevent_destroy = false
    create_before_destroy = false
  }
}

# Public IP for WalletWatch with DNS label for free domain-like access
resource "azurerm_public_ip" "walletwatch" {
  name                = "${var.environment}-walletwatch-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  # This creates: walletwatch-dev.francecentral.cloudapp.azure.com
  domain_name_label   = "walletwatch-${var.environment}"

  tags = var.tags

  # Public IP should be created before AKS cluster uses it
  # No depends_on needed - AKS cluster will reference these IPs

  lifecycle {
    prevent_destroy = false
    create_before_destroy = false
  }
}

# Output the free Azure domains
locals {
  argocd_domain      = "${azurerm_public_ip.argocd.domain_name_label}.${var.location}.cloudapp.azure.com"
  walletwatch_domain = "${azurerm_public_ip.walletwatch.domain_name_label}.${var.location}.cloudapp.azure.com"
}