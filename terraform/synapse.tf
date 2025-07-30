# This Terraform configuration file sets up an Azure Synapse Workspace, a Storage Account, and a Data Lake Gen2 Filesystem.
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_filesystem" {
  name               = "rabo-synapse-filesystem"
  storage_account_id = azurerm_storage_account.storage.id
}

# Create an Azure Synapse Workspace.
# This workspace will be used for data integration, analytics, and big data processing.
# It is configured with a system-assigned managed identity for secure access to other Azure resources.
# The SQL administrator login and password are set using variables defined in variables.tf.
resource "azurerm_synapse_workspace" "synapse" {
  name                                 = "rabo-synapse"
  resource_group_name                  = azurerm_resource_group.rg.name
  location                             = azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_filesystem.id
  sql_administrator_login              = var.synapse_sql_admin_username
  sql_administrator_login_password     = var.synapse_sql_admin_password

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Env = "development"
  }
}

# Assign the Synapse Workspace the Storage Blob Data Contributor role on the Storage Account.
# This allows Synapse to read and write data to the Storage Account.
resource "azurerm_role_assignment" "synapse_storage_access" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapse.identity[0].principal_id
}