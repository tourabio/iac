variable "domain_name" {
  description = "The domain name for the DNS zone"
  type        = string
  default     = "walletwatch.com"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "create_dns_records" {
  description = "Whether to create DNS records (requires LoadBalancer to be deployed)"
  type        = bool
  default     = false
}

variable "aks_cluster_dependency" {
  description = "Dependency on AKS cluster to ensure it's created first"
  type        = any
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}