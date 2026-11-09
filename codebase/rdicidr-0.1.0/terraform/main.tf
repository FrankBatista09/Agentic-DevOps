terraform {
  required_version = ">= 1.9"

  # Partial configuration: the pipeline passes the storage account, container and
  # the per-environment state key with -backend-config. Entra ID auth only, no keys.
  backend "azurerm" {
    use_azuread_auth = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Authentication and the subscription come from the ARM_* environment variables (OIDC).
provider "azurerm" {
  features {}
}

locals {
  prefix = "${var.app_name}-${var.environment}"

  tags = {
    app         = var.app_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

# Short suffix that keeps globally unique names (ACR, public DNS label) unique per environment.
# It lives in the environment's own state, so it is stable once created.
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

# --- Resource Group ---

resource "azurerm_resource_group" "main" {
  name     = "${local.prefix}-rg"
  location = var.location
  tags     = local.tags
}

# --- Log Analytics ---

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.prefix}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

# --- Container Registry ---

resource "azurerm_container_registry" "main" {
  name                = "${var.app_name}${var.environment}${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Basic"
  admin_enabled       = false
  tags                = local.tags
}

# --- Managed Identity ---

resource "azurerm_user_assigned_identity" "app" {
  name                = "${local.prefix}-identity"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

# --- ACR Access (AcrPull is the only role the pipeline identity may assign) ---

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
  principal_type       = "ServicePrincipal"
}

# --- Container App Environment (external, no VNet integration) ---

resource "azurerm_container_app_environment" "main" {
  name                       = "${local.prefix}-env"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  tags                       = local.tags
}

# --- Container App ---

resource "azurerm_container_app" "app" {
  name                         = local.prefix
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  tags                         = local.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.app.id
  }

  ingress {
    target_port                = var.container_port
    external_enabled           = true
    transport                  = "auto"
    allow_insecure_connections = false

    # The gateway is the only way in: traffic from any other address is rejected.
    ip_security_restriction {
      name             = "application-gateway"
      description      = "Only the Application Gateway public IP may reach the app"
      action           = "Allow"
      ip_address_range = "${azurerm_public_ip.gateway.ip_address}/32"
    }

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.app_name
      image  = "${azurerm_container_registry.main.login_server}/${var.image_name}:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      startup_probe {
        transport = "HTTP"
        port      = var.container_port
        path      = var.health_check_path
      }

      readiness_probe {
        transport = "HTTP"
        port      = var.container_port
        path      = var.health_check_path
      }

      liveness_probe {
        transport = "HTTP"
        port      = var.container_port
        path      = var.health_check_path
      }
    }
  }

  # The identity must be allowed to pull before the first revision is created.
  depends_on = [azurerm_role_assignment.acr_pull]
}

# --- Network for the Application Gateway ---

resource "azurerm_virtual_network" "main" {
  name                = "${local.prefix}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_address_spaces[var.environment]]
  tags                = local.tags
}

resource "azurerm_subnet" "gateway" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_spaces[var.environment], 8, 0)]
}

resource "azurerm_network_security_group" "gateway" {
  name                = "${local.prefix}-appgw-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  # Management traffic of Application Gateway v2.
  security_rule {
    name                       = "AllowGatewayManager"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  # Azure load balancer probes.
  security_rule {
    name                       = "AllowAzureLoadBalancer"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # Client traffic. The listener is HTTP only.
  security_rule {
    name                       = "AllowHttpFromInternet"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

# --- Application Gateway (public entry point) ---

resource "azurerm_public_ip" "gateway" {
  name                = "${local.prefix}-appgw-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${local.prefix}-${random_string.suffix.result}"
  tags                = local.tags
}

locals {
  gateway_name = "${local.prefix}-appgw"
}

resource "azurerm_application_gateway" "main" {
  name                = local.gateway_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = azurerm_subnet.gateway.id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "public"
    public_ip_address_id = azurerm_public_ip.gateway.id
  }

  # The backend is the Container App FQDN. The gateway talks to it over HTTPS
  # (the FQDN has a certificate from a public CA, so no root certificate is needed).
  backend_address_pool {
    name  = "container-app"
    fqdns = [azurerm_container_app.app.ingress[0].fqdn]
  }

  backend_http_settings {
    name                                = "container-app-https"
    protocol                            = "Https"
    port                                = 443
    cookie_based_affinity               = "Disabled"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = "health"
  }

  probe {
    name                                      = "health"
    protocol                                  = "Https"
    path                                      = var.health_check_path
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true

    match {
      status_code = ["200"]
    }
  }

  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = "public"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "default"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "http"
    backend_address_pool_name  = "container-app"
    backend_http_settings_name = "container-app-https"
  }

  depends_on = [azurerm_subnet_network_security_group_association.gateway]
}

# --- Access logs ---

resource "azurerm_monitor_diagnostic_setting" "gateway" {
  name                           = "${local.prefix}-appgw-diagnostics"
  target_resource_id             = azurerm_application_gateway.main.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}
