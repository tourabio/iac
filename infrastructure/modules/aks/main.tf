resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.cluster_name}-dns"
  kubernetes_version  = var.kubernetes_version

  # Worker node pool (control plane managed by Azure)
  default_node_pool {
    name                = "default"
    node_count          = var.enable_auto_scaling ? null : var.node_count
    vm_size             = var.vm_size
    enable_auto_scaling = var.enable_auto_scaling
    min_count          = var.enable_auto_scaling ? var.min_count : null
    max_count          = var.enable_auto_scaling ? var.max_count : null
    os_disk_size_gb    = var.os_disk_size_gb
    os_disk_type       = var.os_disk_type

    upgrade_settings {
      max_surge = var.max_surge
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = var.network_plugin
    load_balancer_sku = var.load_balancer_sku
  }

  role_based_access_control_enabled = true

  azure_policy_enabled = var.azure_policy_enabled

  tags = var.tags
}

# Grant AKS access to ACR
# TODO: Uncomment after granting User Access Administrator role to service principal
# Command for admin to run:
# az role assignment create --assignee c408673e-9548-47fa-b2ba-c15194d75375 --role "User Access Administrator" --scope "/subscriptions/56637f11-5e83-404d-b6b3-04c7dab01412"
# resource "azurerm_role_assignment" "aks_acr_pull" {
#   principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
#   role_definition_name             = "AcrPull"
#   scope                            = var.acr_id
#   skip_service_principal_aad_check = true
# }