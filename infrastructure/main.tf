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
  }

  required_version = ">= 1.0"

  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatewalletwatch"
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
  skip_provider_registration = true

  # Use environment variables for authentication in GitHub Actions
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
}

provider "kubernetes" {
  host                   = module.aks.kube_config.0.host
  client_certificate     = base64decode(module.aks.kube_config.0.client_certificate)
  client_key            = base64decode(module.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.0.cluster_ca_certificate)
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

# Azure Container Registry Module
module "acr" {
  source = "./modules/acr"

  acr_name            = var.acr_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled
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
  acr_id                     = module.acr.id
  acr_name                   = module.acr.name
  log_analytics_workspace_id = var.log_analytics_workspace_id
  tags                       = local.common_tags

  depends_on = [module.acr]
}

# Public DNS Module (Free Azure Domain)
module "public_dns" {
  source = "./modules/public-dns"

  environment         = var.environment
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = local.common_tags
}