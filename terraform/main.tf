# 1. Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "faisalstorageejlu11"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    
    # ⚠️ THIS ID TELLS TERRAFORM: "USE THE STUDENT ACCOUNT"
    subscription_id      = "d7630421-2fe7-43fc-86c4-647b59ecfe84"
  }
}

provider "azurerm" {
  features {}
  # It is good practice to put it here too
  subscription_id = "d7630421-2fe7-43fc-86c4-647b59ecfe84"
}

# 2. Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "student-project-rg"
  location = "UK South"
}

# 3. Create the App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "student-app-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

# 4. Create the Web App
resource "azurerm_linux_web_app" "webapp" {
  name                = "faisal-azure-app-ejlu11"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    always_on = false
    
    application_stack {
      dotnet_version = "6.0"
    }
  }

  # Connection string configuration
  connection_string {
    name  = "MyDbConnection"
    type  = "SQLAzure"
    value = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.db.name};Persist Security Info=False;User ID=sqladmin;Password=P@ssw0rd1234!;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  }
}

# 5. Create the SQL Server
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "faisal-sql-server-ejlu11"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd1234!"
}

# 6. Create the Database
resource "azurerm_mssql_database" "db" {
  name           = "TodoDb"
  server_id      = azurerm_mssql_server.sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 2
  sku_name       = "S0" 
}

# 7. Firewall Rule
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}