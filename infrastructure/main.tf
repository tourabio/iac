terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.116.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"
    }
  }

  required_version = ">= 1.0"

  backend "azurerm" {
    resource_group_name  = "terraform-state-francecentral-rg"
    storage_account_name = "tfstatefrancecentralww"
    container_name       = "tfstate"
    key                  = "walletwatch.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id            = var.subscription_id
  skip_provider_registration = false

  # Use environment variables for authentication in GitHub Actions
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
}

provider "kubernetes" {
  host                   = module.aks.kube_config.0.host
  client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
  client_key            = base64decode(module.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
}


# JWT Key Generation
resource "tls_private_key" "jwt_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Convert RSA private key from PKCS#1 to PKCS#8 format (required by SmallRye JWT)
# Using external data source to run OpenSSL conversion
data "external" "jwt_private_key_pkcs8" {
  program = ["bash", "-c", "echo '${tls_private_key.jwt_key.private_key_pem}' | openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt | jq -Rs '{private_key: .}'"]

  depends_on = [tls_private_key.jwt_key]
}

# Local values for common tags
locals {
  common_tags = {
    environment = var.environment
    project     = "walletwatch"
    managed_by  = "terraform"
  }
}

# Resource Group Module
module "resource_group" {
  source = "./modules/resource-group"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.common_tags
}


# Azure Kubernetes Service Module
module "aks" {
  source = "./modules/aks"

  cluster_name               = var.aks_cluster_name
  resource_group_name        = module.resource_group.name
  location                   = module.resource_group.location
  kubernetes_version         = var.kubernetes_version
  node_count                 = var.aks_node_count
  vm_size                    = var.aks_vm_size
  enable_auto_scaling        = var.aks_enable_auto_scaling
  min_count                  = var.aks_min_nodes
  max_count                  = var.aks_max_nodes
  os_disk_size_gb            = var.aks_os_disk_size_gb
  os_disk_type               = var.aks_os_disk_type
  max_surge                  = var.aks_max_surge
  network_plugin             = var.aks_network_plugin
  load_balancer_sku          = var.aks_load_balancer_sku
  azure_policy_enabled       = var.aks_azure_policy_enabled
  persistent_resource_group_name = var.persistent_resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = local.common_tags

}

# Public DNS Module (Free Azure Domain)
module "public_dns" {
  source = "./modules/public-dns"

  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = local.common_tags
  aks_cluster_dependency = module.aks
}

# Azure Container Registry Module
module "acr" {
  source = "./modules/acr"

  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled
  tags                = local.common_tags
}

# Key Vault Module
module "keyvault" {
  source = "./modules/keyvault"

  environment                    = var.environment
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  persistent_resource_group_name = var.persistent_resource_group_name
  sku_name                       = var.keyvault_sku_name
  enabled_for_disk_encryption     = var.keyvault_enabled_for_disk_encryption
  enabled_for_deployment          = var.keyvault_enabled_for_deployment
  enabled_for_template_deployment = var.keyvault_enabled_for_template_deployment
  enable_rbac_authorization       = var.keyvault_enable_rbac_authorization
  soft_delete_retention_days      = var.keyvault_soft_delete_retention_days
  purge_protection_enabled        = var.keyvault_purge_protection_enabled
  network_acls_default_action     = var.keyvault_network_acls_default_action
  network_acls_bypass             = var.keyvault_network_acls_bypass
  network_acls_ip_rules           = var.keyvault_network_acls_ip_rules
  tags                            = local.common_tags
}

# PostgreSQL Flexible Server Module
module "postgresql" {
  source = "./modules/postgresql"

  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  postgresql_version             = var.postgresql_version
  admin_username                 = var.postgresql_admin_username
  database_name                  = var.postgresql_database_name
  sku_name                       = var.postgresql_sku_name
  storage_mb                     = var.postgresql_storage_mb
  backup_retention_days          = var.postgresql_backup_retention_days
  availability_zone              = var.postgresql_availability_zone
  tags                           = local.common_tags
}

# Key Vault Secrets Module for Database, Flyway, and JWT Credentials
module "keyvault_secrets" {
  source = "./modules/keyvault-secrets"

  environment                    = var.environment
  resource_group_name            = module.resource_group.name
  keyvault_id                    = module.keyvault.id
  database_host                  = module.postgresql.server_fqdn
  database_port                  = "5432"
  database_name                  = module.postgresql.database_name
  database_username              = module.postgresql.admin_username
  database_password              = module.postgresql.admin_password

  # Flyway credentials (reuse PostgreSQL admin credentials)
  flyway_connect_user            = module.postgresql.admin_username
  flyway_connect_user_password   = module.postgresql.admin_password

  # JWT keys (base64 encoded for multiline content)
  jwt_public_key                 = base64encode(tls_private_key.jwt_key.public_key_pem)
  jwt_private_key                = base64encode(data.external.jwt_private_key_pkcs8.result.private_key)

  tags                           = local.common_tags

  depends_on = [module.postgresql, module.keyvault, tls_private_key.jwt_key, data.external.jwt_private_key_pkcs8]
}