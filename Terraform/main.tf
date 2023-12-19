# Use Azure Terraform provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.75.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create azure resource group
resource "azurerm_resource_group" "azvrg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}
# Create azure service Plan
resource "azurerm_service_plan" "azvsp" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.azvrg.location
  resource_group_name = azurerm_resource_group.azvrg.name
  os_type             = "Linux"
  sku_name            = "F1"
}
# Create Azure Web App and add connection string, site configure
resource "azurerm_linux_web_app" "azlwebapp" {
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.azvrg.name
  location            = azurerm_service_plan.azvsp.location
  service_plan_id     = azurerm_service_plan.azvsp.id

  connection_string {
    name  = "DefaultConnection"
    type  = "SQLAzure"
    value = "Data Source=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.database.name};User ID=${azurerm_mssql_server.sqlserver.administrator_login};Password=${azurerm_mssql_server.sqlserver.administrator_login_password};Trusted_Connection=False; MultipleActiveResultSets=True;"
  }

  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
    always_on = false
  }
}
# Create Azure App service control
resource "azurerm_app_service_source_control" "azapssc" {
  app_id                 = azurerm_linux_web_app.azlwebapp.id
  repo_url               = var.repo_URL
  branch                 = "main"
  use_manual_integration = true
}
resource "azurerm_mssql_server" "sqlserver" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.azvrg.name
  location                     = azurerm_resource_group.azvrg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = var.sql_admin_password
}
resource "azurerm_mssql_database" "database" {
  name           = var.sql_database_name
  server_id      = azurerm_mssql_server.sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "S0"
  zone_redundant = false
}
resource "azurerm_mssql_firewall_rule" "firewall" {
  name             = var.firewall_rule_name
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
