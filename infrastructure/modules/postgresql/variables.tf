variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for PostgreSQL server"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "16"
  validation {
    condition     = contains(["13", "14", "15", "16"], var.postgresql_version)
    error_message = "PostgreSQL version must be 13, 14, 15, or 16."
  }
}

variable "admin_username" {
  description = "Administrator username for PostgreSQL"
  type        = string
  default     = "walletwatch_admin"
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "walletwatch"
}

variable "sku_name" {
  description = "The SKU Name for the PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"
  validation {
    condition = can(regex("^(B_Standard_B[0-9]+m?s|GP_Standard_D[0-9]+s_v[0-9]+|MO_Standard_E[0-9]+s_v[0-9]+)$", var.sku_name))
    error_message = "SKU name must be a valid PostgreSQL Flexible Server SKU."
  }
}

variable "storage_mb" {
  description = "Storage size in MB (minimum 32GB for cost efficiency)"
  type        = number
  default     = 32768
  validation {
    condition     = var.storage_mb >= 32768 && var.storage_mb <= 65536
    error_message = "Storage size must be between 32768 MB (32 GB) and 65536 MB (64 GB) for cost efficiency."
  }
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Backup retention days must be between 7 and 35."
  }
}

variable "geo_redundant_backup_enabled" {
  description = "Enable geo-redundant backup (disabled for cost savings)"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "Availability zone for the PostgreSQL server"
  type        = string
  default     = "1"
  validation {
    condition     = contains(["1", "2", "3"], var.availability_zone)
    error_message = "Availability zone must be 1, 2, or 3."
  }
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}