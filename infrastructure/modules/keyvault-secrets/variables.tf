variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group containing the Key Vault"
  type        = string
}

variable "keyvault_id" {
  description = "ID of the Key Vault to store secrets in"
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

# Flyway Secrets Variables
variable "flyway_connect_user" {
  description = "Flyway database connection username"
  type        = string
}

variable "flyway_connect_user_password" {
  description = "Flyway database connection password"
  type        = string
  sensitive   = true
}

# JWT Key Variables
variable "jwt_public_key" {
  description = "JWT public key content (PEM format, base64 encoded)"
  type        = string
  sensitive   = true
}

variable "jwt_private_key" {
  description = "JWT private key content (PKCS#8 format, base64 encoded)"
  type        = string
  sensitive   = true
}