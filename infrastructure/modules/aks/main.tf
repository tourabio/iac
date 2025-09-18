# Reference existing User Assigned Managed Identity created by admin in persistent RG
data "azurerm_user_assigned_identity" "aks_kubelet" {
  name                = "${var.cluster_name}-kubelet-identity"
  resource_group_name = var.persistent_resource_group_name
}

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
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.aks_kubelet.id]
  }

  kubelet_identity {
    client_id                 = data.azurerm_user_assigned_identity.aks_kubelet.client_id
    object_id                 = data.azurerm_user_assigned_identity.aks_kubelet.principal_id
    user_assigned_identity_id = data.azurerm_user_assigned_identity.aks_kubelet.id
  }

  network_profile {
    network_plugin    = var.network_plugin
    load_balancer_sku = var.load_balancer_sku
  }

  role_based_access_control_enabled = true

  azure_policy_enabled = var.azure_policy_enabled

  tags = var.tags
}

# NOTE: Admin needs to manually grant AcrPull role to the kubelet identity
# Use the kubelet_identity_principal_id output to assign the role manually