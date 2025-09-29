variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault"
  type        = string
}

variable "persistent_resource_group_name" {
  description = "Name of the persistent resource group containing identities"
  type        = string
}

variable "sku_name" {
  description = "SKU name for the Key Vault"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "SKU name must be standard or premium."
  }
}

variable "enabled_for_disk_encryption" {
  description = "Enable Key Vault for disk encryption"
  type        = bool
  default     = false
}

variable "enabled_for_deployment" {
  description = "Enable Key Vault for deployment"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Enable Key Vault for template deployment"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for Key Vault"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft deleted items"
  type        = number
  default     = 7
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = false
}

variable "network_acls_default_action" {
  description = "Default action for network ACLs"
  type        = string
  default     = "Allow"
  validation {
    condition     = contains(["Allow", "Deny"], var.network_acls_default_action)
    error_message = "Default action must be Allow or Deny."
  }
}

variable "network_acls_bypass" {
  description = "Bypass option for network ACLs"
  type        = string
  default     = "AzureServices"
  validation {
    condition     = contains(["AzureServices", "None"], var.network_acls_bypass)
    error_message = "Bypass must be AzureServices or None."
  }
}

variable "network_acls_ip_rules" {
  description = "List of IP rules for network ACLs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the Key Vault"
  type        = map(string)
  default     = {}
}