variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region where the AKS cluster will be created"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use for the AKS cluster"
  type        = string
  default     = "1.29.9"
}

variable "node_count" {
  description = "Initial number of worker nodes"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "Size of the virtual machines for worker nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "enable_auto_scaling" {
  description = "Enable auto-scaling for the node pool"
  type        = bool
  default     = true
}

variable "min_count" {
  description = "Minimum number of nodes in the auto-scaling pool"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum number of nodes in the auto-scaling pool"
  type        = number
  default     = 3
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for monitoring"
  type        = string
  default     = null
}


variable "os_disk_size_gb" {
  description = "OS disk size in GB for worker nodes"
  type        = number
  default     = 30
}

variable "os_disk_type" {
  description = "OS disk type for worker nodes"
  type        = string
  default     = "Managed"
}

variable "max_surge" {
  description = "Maximum number of nodes that can be created during an upgrade"
  type        = string
  default     = "10%"
}

variable "network_plugin" {
  description = "Network plugin for AKS cluster"
  type        = string
  default     = "kubenet"
  validation {
    condition     = contains(["azure", "kubenet"], var.network_plugin)
    error_message = "Network plugin must be either 'azure' or 'kubenet'."
  }
}

variable "load_balancer_sku" {
  description = "SKU for the load balancer"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["basic", "standard"], var.load_balancer_sku)
    error_message = "Load balancer SKU must be either 'basic' or 'standard'."
  }
}

variable "azure_policy_enabled" {
  description = "Enable Azure Policy for AKS cluster"
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resources"
  type        = map(string)
  default     = {}
}

variable "persistent_resource_group_name" {
  description = "Name of the persistent resource group containing pre-created ACR and identity"
  type        = string
}