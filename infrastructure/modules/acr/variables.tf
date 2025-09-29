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
  description = "Azure region for the ACR"
  type        = string
}

variable "sku" {
  description = "SKU for the Azure Container Registry"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "SKU must be Basic, Standard, or Premium."
  }
}

variable "admin_enabled" {
  description = "Enable admin user for the ACR"
  type        = bool
  default     = false
}

variable "georeplications" {
  description = "List of georeplications for the ACR (Premium SKU only)"
  type = list(object({
    location                = string
    zone_redundancy_enabled = bool
  }))
  default = []
}

variable "network_rule_set_enabled" {
  description = "Enable network rule set for the ACR"
  type        = bool
  default     = false
}

variable "network_rule_default_action" {
  description = "Default action for network rule set"
  type        = string
  default     = "Allow"
  validation {
    condition     = contains(["Allow", "Deny"], var.network_rule_default_action)
    error_message = "Default action must be Allow or Deny."
  }
}

variable "network_rule_ip_ranges" {
  description = "List of IP ranges to allow access to ACR"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the ACR"
  type        = map(string)
  default     = {}
}