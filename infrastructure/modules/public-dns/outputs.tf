output "public_ip" {
  description = "The public IP address"
  value       = azurerm_public_ip.main.ip_address
}

output "argocd_fqdn" {
  description = "FQDN for ArgoCD (Free Azure domain)"
  value       = local.azure_domain
}

output "argocd_url" {
  description = "ArgoCD URL with HTTPS"
  value       = "https://${local.azure_domain}"
}

output "domain_name_label" {
  description = "Domain name label"
  value       = azurerm_public_ip.main.domain_name_label
}