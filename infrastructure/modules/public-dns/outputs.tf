output "argocd_public_ip" {
  description = "The ArgoCD public IP address"
  value       = azurerm_public_ip.argocd.ip_address
}

output "walletwatch_public_ip" {
  description = "The WalletWatch public IP address"
  value       = azurerm_public_ip.walletwatch.ip_address
}

output "argocd_fqdn" {
  description = "FQDN for ArgoCD (Free Azure domain)"
  value       = local.argocd_domain
}

output "walletwatch_fqdn" {
  description = "FQDN for WalletWatch (Free Azure domain)"
  value       = local.walletwatch_domain
}

output "argocd_url" {
  description = "ArgoCD URL with HTTPS"
  value       = "https://${local.argocd_domain}"
}

output "walletwatch_url" {
  description = "WalletWatch URL with HTTPS"
  value       = "https://${local.walletwatch_domain}"
}

# Legacy outputs for backward compatibility
output "public_ip" {
  description = "The ArgoCD public IP address (legacy)"
  value       = azurerm_public_ip.argocd.ip_address
}

output "domain_name_label" {
  description = "ArgoCD domain name label (legacy)"
  value       = azurerm_public_ip.argocd.domain_name_label
}