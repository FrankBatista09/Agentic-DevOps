output "gateway_url" {
  value       = "http://${azurerm_public_ip.gateway.fqdn}"
  description = "Public URL of the application, through the Application Gateway"
}

output "health_url" {
  value       = "http://${azurerm_public_ip.gateway.fqdn}${var.health_check_path}"
  description = "Public health check URL, through the Application Gateway"
}

output "app_gateway_public_ip" {
  value       = azurerm_public_ip.gateway.ip_address
  description = "Public IP address of the Application Gateway"
}

output "app_gateway_fqdn" {
  value       = azurerm_public_ip.gateway.fqdn
  description = "DNS name of the Application Gateway public IP"
}

output "container_app_fqdn" {
  value       = azurerm_container_app.app.ingress[0].fqdn
  description = "FQDN of the Container App (only reachable from the gateway public IP)"
}

output "container_app_name" {
  value       = azurerm_container_app.app.name
  description = "Container App name"
}

output "environment_name" {
  value       = azurerm_container_app_environment.main.name
  description = "Container App Environment name"
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource group of this environment"
}

output "acr_name" {
  value       = azurerm_container_registry.main.name
  description = "Container registry name"
}

output "acr_login_server" {
  value       = azurerm_container_registry.main.login_server
  description = "Container registry login server"
}

output "log_analytics_workspace_name" {
  value       = azurerm_log_analytics_workspace.main.name
  description = "Log Analytics workspace that receives the access logs"
}
