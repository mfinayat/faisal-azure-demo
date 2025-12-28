# 1. Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# 2. Create a Resource Group (A folder for all your cloud resources)
resource "azurerm_resource_group" "rg" {
  name     = "student-project-rg"
  location = "UK South" # You can change this to "East US" etc.
}

# 3. Create the App Service Plan (The computer power behind the web app)
resource "azurerm_service_plan" "plan" {
  name                = "student-app-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "F1" # F1 is the FREE tier!
}

# 4. Create the Web App (The actual website host)
resource "azurerm_linux_web_app" "webapp" {
  name                = "faisal-azure-app-ejlu11"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    # YOU MUST ADD THIS LINE FOR FREE TIER
    always_on = false

    application_stack {
      dotnet_version = "6.0"
    }
  }

  # Connection string so the app knows how to talk to the DB
  connection_string {
    name  = "AZURE_SQL_CONNECTIONSTRING"
    type  = "SQLAzure"
    value = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.db.name};Persist Security Info=False;User ID=sqladmin;Password=P@ssw0rd1234!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }
}

# 5. Create the SQL Server (Logical container for databases)
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "faisal-sql-server-ejlu11" # CHANGE THIS to be globally unique
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd1234!" # In real life, use a variable!
}

# 6. Create the Database
resource "azurerm_mssql_database" "db" {
  name           = "TodoDb"
  server_id      = azurerm_mssql_server.sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "S0" # Basic tier
}

# 7. Firewall Rule (Allow Azure services to reach the DB)
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}