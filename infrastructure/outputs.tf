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

output "aks_kubelet_identity_principal_id" {
  description = "Principal ID of the AKS kubelet user-assigned identity (static)"
  value       = module.aks.kubelet_identity_principal_id
}

output "aks_kubelet_identity_client_id" {
  description = "Client ID of the AKS kubelet user-assigned identity"
  value       = module.aks.kubelet_identity_client_id
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