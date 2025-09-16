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

# Grant AKS access to ACR using attach method (no tenant-wide permissions needed)
resource "null_resource" "attach_acr" {
  count = var.acr_name != null ? 1 : 0

  provisioner "local-exec" {
    command = "az aks update -n ${azurerm_kubernetes_cluster.aks.name} -g ${var.resource_group_name} --attach-acr ${var.acr_name}"
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}