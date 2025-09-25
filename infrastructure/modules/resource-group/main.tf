# Reference existing manually created resource group
# Admin must create this resource group manually before running terraform
data "azurerm_resource_group" "default" {
  name = var.resource_group_name
}