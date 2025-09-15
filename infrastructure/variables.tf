variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "domain_name" {
  description = "Domain name for DNS zone"
  type        = string
  default     = "walletwatch.com"
}

variable "create_dns_records" {
  description = "Whether to create DNS records (requires LoadBalancer to be deployed)"
  type        = bool
  default     = false
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "walletwatchacr"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "walletwatchacr"
}

variable "acr_sku" {
  description = "SKU for the Azure Container Registry"
  type        = string
  default     = "Basic"
}

variable "acr_admin_enabled" {
  description = "Enable admin user for ACR"
  type        = bool
  default     = false
}

# AKS Variables
variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "walletwatch-dev-aks"
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use for the AKS cluster"
  type        = string
  default     = "1.28.3"
}

variable "aks_node_count" {
  description = "Initial number of worker nodes in the AKS cluster"
  type        = number
  default     = 1
}

variable "aks_vm_size" {
  description = "Size of the virtual machines for AKS worker nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "aks_enable_auto_scaling" {
  description = "Enable auto-scaling for the AKS node pool"
  type        = bool
  default     = true
}

variable "aks_min_nodes" {
  description = "Minimum number of nodes in the AKS auto-scaling pool"
  type        = number
  default     = 1
}

variable "aks_max_nodes" {
  description = "Maximum number of nodes in the AKS auto-scaling pool"
  type        = number
  default     = 3
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace for AKS monitoring"
  type        = string
  default     = null
}

variable "aks_os_disk_size_gb" {
  description = "OS disk size in GB for AKS worker nodes"
  type        = number
  default     = 30
}

variable "aks_os_disk_type" {
  description = "OS disk type for AKS worker nodes"
  type        = string
  default     = "Managed"
}

variable "aks_max_surge" {
  description = "Maximum number of nodes that can be created during an upgrade"
  type        = string
  default     = "10%"
}

variable "aks_network_plugin" {
  description = "Network plugin for AKS cluster"
  type        = string
  default     = "kubenet"
}

variable "aks_load_balancer_sku" {
  description = "SKU for the load balancer"
  type        = string
  default     = "standard"
}

variable "aks_azure_policy_enabled" {
  description = "Enable Azure Policy for AKS cluster"
  type        = bool
  default     = false
}