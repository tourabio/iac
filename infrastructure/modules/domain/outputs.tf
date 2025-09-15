output "domain_name" {
  description = "The purchased domain name"
  value       = azurerm_app_service_domain.main.name
}

output "domain_id" {
  description = "ID of the purchased domain"
  value       = azurerm_app_service_domain.main.id
}

output "dns_zone_name" {
  description = "Name of the DNS zone"
  value       = azurerm_dns_zone.main.name
}

output "dns_zone_id" {
  description = "ID of the DNS zone"
  value       = azurerm_dns_zone.main.id
}

output "name_servers" {
  description = "Name servers for the DNS zone"
  value       = azurerm_dns_zone.main.name_servers
}

output "argocd_fqdn" {
  description = "FQDN for ArgoCD"
  value       = var.create_dns_records ? azurerm_dns_a_record.argocd[0].fqdn : "argocd-${var.environment}.${azurerm_app_service_domain.main.name}"
}

output "app_fqdn" {
  description = "FQDN for the application"
  value       = var.create_dns_records ? azurerm_dns_a_record.app[0].fqdn : "${var.environment}.${azurerm_app_service_domain.main.name}"
}