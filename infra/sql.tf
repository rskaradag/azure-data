# ------------------------------------------------------------------------------------------------------
# Deploy mssql server and database
# ------------------------------------------------------------------------------------------------------
# This Terraform configuration file sets up a SQL Server and a SQL Database in Azure.
# It uses the azurerm provider to create resources in Azure.
resource "azurerm_mssql_server" "sql_server_rabo" {
  name                         = var.sqlserver_name
  resource_group_name          = azurerm_resource_group.rg_rabo.name
  location                     = azurerm_resource_group.rg_rabo.location
  version                      = "12.0"
  administrator_login          = "sqladminuser"
  administrator_login_password = var.sql_admin_password

  tags = merge(local.rg_tags)

}

# Create a SQL Database within the SQL Server. This is a basic setup.
# For production, consider using a more robust configuration.
resource "azurerm_mssql_database" "sql_db_rabo" {
  name           = var.db_name
  server_id      = azurerm_mssql_server.sql_server_rabo.id
  sku_name       = "Basic"
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 2
  zone_redundant = false
  read_scale     = false

  tags = merge(local.rg_tags)  
}

# Allow local connections to the SQL Server. This is useful for development and testing. will be removed in production.
resource "azurerm_mssql_firewall_rule" "fw_rule_mssql_rabo" {
  name             = "AllowLocal"
  server_id        = azurerm_mssql_server.sql_server_rabo.id
  start_ip_address     = trim(data.http.client_ip.response_body, "\n")
  end_ip_address       = trim(data.http.client_ip.response_body, "\n")
}

