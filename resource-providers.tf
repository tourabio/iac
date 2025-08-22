# Register required Azure Resource Providers
resource "azurerm_resource_provider_registration" "container_registry" {
  name = "Microsoft.ContainerRegistry"
}

resource "azurerm_resource_provider_registration" "container_service" {
  name = "Microsoft.ContainerService"
}

resource "azurerm_resource_provider_registration" "compute" {
  name = "Microsoft.Compute"
}

resource "azurerm_resource_provider_registration" "network" {
  name = "Microsoft.Network"
}

resource "azurerm_resource_provider_registration" "storage" {
  name = "Microsoft.Storage"
}