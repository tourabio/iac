terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.67.0"
    }
  }

  required_version = ">= 0.14"

  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstatewalletwatch"
    container_name       = "tfstate"
    key                  = "walletwatch.tfstate"
  }
}

provider "azurerm" {
  features {}
  subscription_id            = var.subscription_id
  skip_provider_registration = true

  # Use environment variables for authentication in GitHub Actions
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID
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