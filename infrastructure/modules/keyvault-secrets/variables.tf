variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "persistent_resource_group_name" {
  description = "Name of the persistent resource group containing the Key Vault"
  type        = string
}

variable "database_host" {
  description = "Database host/FQDN"
  type        = string
}

variable "database_port" {
  description = "Database port"
  type        = string
  default     = "5432"
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "database_username" {
  description = "Database username"
  type        = string
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}