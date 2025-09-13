output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "kubelet_identity" {
  description = "Kubelet identity of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity
}

output "principal_id" {
  description = "Principal ID of the system assigned identity"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "tenant_id" {
  description = "Tenant ID of the system assigned identity"
  value       = azurerm_kubernetes_cluster.aks.identity[0].tenant_id
}