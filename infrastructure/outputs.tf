output "resource_group_name" {
  description = "Name of the resource group"
  value       = module.resource_group.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = module.resource_group.location
}


# AKS Outputs
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = module.aks.cluster_fqdn
}


# Public DNS Outputs (Free Azure Domain)
output "argocd_public_ip" {
  description = "Public IP address for ArgoCD"
  value       = module.public_dns.public_ip
}

output "argocd_fqdn" {
  description = "Free Azure domain for ArgoCD"
  value       = module.public_dns.argocd_fqdn
}

output "argocd_url" {
  description = "ArgoCD URL (Free Azure Domain)"
  value       = module.public_dns.argocd_url
}

# ACR Outputs
output "acr_name" {
  description = "Name of the Azure Container Registry"
  value       = module.acr.name
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry"
  value       = module.acr.login_server
}

output "acr_id" {
  description = "ID of the Azure Container Registry"
  value       = module.acr.id
}

# Key Vault Outputs
output "keyvault_name" {
  description = "Name of the Key Vault"
  value       = module.keyvault.name
}

output "keyvault_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.keyvault.vault_uri
}

output "keyvault_id" {
  description = "ID of the Key Vault"
  value       = module.keyvault.id
}

# PostgreSQL Outputs
output "postgresql_server_name" {
  description = "Name of the PostgreSQL Flexible Server"
  value       = module.postgresql.server_name
}

output "postgresql_server_fqdn" {
  description = "FQDN of the PostgreSQL Flexible Server"
  value       = module.postgresql.server_fqdn
}

output "postgresql_database_name" {
  description = "Name of the PostgreSQL database"
  value       = module.postgresql.database_name
}

# Key Vault Secrets Outputs
output "keyvault_secret_names" {
  description = "Names of the database secrets stored in Key Vault"
  value       = module.keyvault_secrets.secret_names
}