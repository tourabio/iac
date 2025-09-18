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

output "kube_config" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config
  sensitive   = true
}

output "kubelet_identity_principal_id" {
  description = "Principal ID of the kubelet user-assigned identity (static - admin pre-created)"
  value       = data.azurerm_user_assigned_identity.aks_kubelet.principal_id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the kubelet user-assigned identity"
  value       = data.azurerm_user_assigned_identity.aks_kubelet.client_id
}

output "kubelet_identity_id" {
  description = "Resource ID of the kubelet user-assigned identity"
  value       = data.azurerm_user_assigned_identity.aks_kubelet.id
}