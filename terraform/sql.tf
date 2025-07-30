# This Terraform configuration file sets up a SQL Server and a SQL Database in Azure.
# It uses the azurerm provider to create resources in Azure.
resource "azurerm_mssql_server" "sql_server" {
  name                         = var.sqlserver_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = var.sql_admin_password
}

# Create a SQL Database within the SQL Server. This is a basic setup.
# For production, consider using a more robust configuration.
resource "azurerm_mssql_database" "sql_db" {
  name                = var.db_name
  server_id           = azurerm_mssql_server.sql_server.id
  sku_name            = "Basic"
  collation           = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb         = 2
  zone_redundant      = false
  read_scale          = false
}

# Allow local connections to the SQL Server. This is useful for development and testing. can be removed in production.
resource "azurerm_mssql_firewall_rule" "allow_local" {
  name             = "AllowLocal"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

