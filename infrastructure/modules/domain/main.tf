# Azure App Service Domain
resource "azurerm_app_service_domain" "main" {
  name                = var.domain_name
  resource_group_name = var.resource_group_name
  location            = "global"  # App Service domains are global

  tags = var.tags

  # Auto-renewal for the domain
  auto_renew = true
}

# DNS Zone for the domain
resource "azurerm_dns_zone" "main" {
  name                = azurerm_app_service_domain.main.name
  resource_group_name = var.resource_group_name
  tags                = var.tags

  depends_on = [azurerm_app_service_domain.main]
}

# Data source to get NGINX LoadBalancer IP
data "kubernetes_service" "nginx_ingress" {
  count = var.create_dns_records ? 1 : 0

  metadata {
    name      = "nginx-ingress-ingress-nginx-controller"
    namespace = "nginx-ingress"
  }

  depends_on = [var.aks_cluster_dependency]
}

# ArgoCD DNS Record
resource "azurerm_dns_a_record" "argocd" {
  count = var.create_dns_records ? 1 : 0

  name                = "argocd-${var.environment}"
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [data.kubernetes_service.nginx_ingress[0].status.0.load_balancer.0.ingress.0.ip]
  tags                = var.tags

  depends_on = [data.kubernetes_service.nginx_ingress]
}

# WalletWatch App DNS Record
resource "azurerm_dns_a_record" "app" {
  count = var.create_dns_records ? 1 : 0

  name                = var.environment
  zone_name           = azurerm_dns_zone.main.name
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [data.kubernetes_service.nginx_ingress[0].status.0.load_balancer.0.ingress.0.ip]
  tags                = var.tags

  depends_on = [data.kubernetes_service.nginx_ingress]
}