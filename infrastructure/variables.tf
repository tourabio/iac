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

variable "persistent_resource_group_name" {
  description = "Name of the persistent resource group containing pre-created ACR and identity"
  type        = string
}

# PostgreSQL Variables
variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
  validation {
    condition     = contains(["13", "14", "15", "16"], var.postgresql_version)
    error_message = "PostgreSQL version must be 13, 14, 15, or 16."
  }
}

variable "postgresql_admin_username" {
  description = "Administrator username for PostgreSQL"
  type        = string
  default     = "walletwatch_admin"
}

variable "postgresql_database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "walletwatch"
}

variable "postgresql_sku_name" {
  description = "The SKU Name for the PostgreSQL Flexible Server (cost-optimized)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgresql_storage_mb" {
  description = "Storage size in MB (32GB for cost efficiency)"
  type        = number
  default     = 32768
}

variable "postgresql_backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "postgresql_availability_zone" {
  description = "Availability zone for the PostgreSQL server"
  type        = string
  default     = "1"
}

# ACR Variables
variable "acr_sku" {
  description = "SKU for the Azure Container Registry"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "ACR SKU must be Basic, Standard, or Premium."
  }
}

variable "acr_admin_enabled" {
  description = "Enable admin user for the ACR"
  type        = bool
  default     = false
}

variable "acr_georeplications" {
  description = "List of georeplications for the ACR (Premium SKU only)"
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
  }))
  default = []
}

variable "acr_network_rule_set_enabled" {
  description = "Enable network rule set for the ACR"
  type        = bool
  default     = false
}

variable "acr_network_rule_default_action" {
  description = "Default action for ACR network rule set"
  type        = string
  default     = "Allow"
  validation {
    condition     = contains(["Allow", "Deny"], var.acr_network_rule_default_action)
    error_message = "Default action must be Allow or Deny."
  }
}

variable "acr_network_rule_ip_ranges" {
  description = "List of IP ranges to allow access to ACR"
  type        = list(string)
  default     = []
}

# Key Vault Variables
variable "keyvault_sku_name" {
  description = "SKU name for the Key Vault"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.keyvault_sku_name)
    error_message = "Key Vault SKU name must be standard or premium."
  }
}

variable "keyvault_enabled_for_disk_encryption" {
  description = "Enable Key Vault for disk encryption"
  type        = bool
  default     = false
}

variable "keyvault_enabled_for_deployment" {
  description = "Enable Key Vault for deployment"
  type        = bool
  default     = false
}

variable "keyvault_enabled_for_template_deployment" {
  description = "Enable Key Vault for template deployment"
  type        = bool
  default     = false
}

variable "keyvault_enable_rbac_authorization" {
  description = "Enable RBAC authorization for Key Vault"
  type        = bool
  default     = true
}

variable "keyvault_soft_delete_retention_days" {
  description = "Number of days to retain soft deleted items in Key Vault"
  type        = number
  default     = 7
  validation {
    condition     = var.keyvault_soft_delete_retention_days >= 7 && var.keyvault_soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "keyvault_purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = false
}

variable "keyvault_network_acls_default_action" {
  description = "Default action for Key Vault network ACLs"
  type        = string
  default     = "Allow"
  validation {
    condition     = contains(["Allow", "Deny"], var.keyvault_network_acls_default_action)
    error_message = "Default action must be Allow or Deny."
  }
}

variable "keyvault_network_acls_bypass" {
  description = "Bypass option for Key Vault network ACLs"
  type        = string
  default     = "AzureServices"
  validation {
    condition     = contains(["AzureServices", "None"], var.keyvault_network_acls_bypass)
    error_message = "Bypass must be AzureServices or None."
  }
}

variable "keyvault_network_acls_ip_rules" {
  description = "List of IP rules for Key Vault network ACLs"
  type        = list(string)
  default     = []
}