# Azure Container Registry with minimal cost configuration
resource "azurerm_container_registry" "acr" {
  name                = "tundevdaysacr"
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    environment = "dev"
  }
}
