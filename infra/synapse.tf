# ------------------------------------------------------------------------------------------------------
# Deploy File system and Synapse Workspace
# ------------------------------------------------------------------------------------------------------
# This Terraform configuration file sets up an Azure Synapse Workspace, a Storage Account, and a Data Lake Gen2 Filesystem.
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_filesystem" {
  name               = local.resourceNames.synapseFilesytemName
  storage_account_id = azurerm_storage_account.storage_rabo.id
}

# Create an Azure Synapse Workspace.
# This workspace will be used for data integration, analytics, and big data processing.
# It is configured with a system-assigned managed identity for secure access to other Azure resources.
# The SQL administrator login and password are set using variables defined in variables.tf.
resource "azurerm_synapse_workspace" "synapse_ws_rabo" {
  name                                 = local.resourceNames.sysnapseWorkspaceName
  resource_group_name                  = azurerm_resource_group.rg_rabo.name
  location                             = azurerm_resource_group.rg_rabo.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_filesystem.id
  sql_administrator_login              = var.synapse_sql_admin_username
  sql_administrator_login_password     = var.synapse_sql_admin_password

  identity {
    type = "SystemAssigned"
  }

  tags = merge(local.rg_tags)
}

# ------------------------------------------------------------------------------------------------------
# Deploy Spark Pool
# ------------------------------------------------------------------------------------------------------
resource "azurerm_synapse_spark_pool" "spark_pool_rabo" {
  name                 = local.resourceNames.synapseSparkPoolName
  synapse_workspace_id = azurerm_synapse_workspace.synapse_ws_rabo.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  cache_size           = 100

  auto_scale {
    # max pool size is set to 2 nodes, which allows for scaling up to handle larger workloads.
    max_node_count = 3
    min_node_count = 3
  }

  library_requirement {
    content  = <<EOF
azure-identity==1.23.1
azure-keyvault-secrets==4.10.0
EOF
    filename = "requirements.txt"
  }

  spark_config {
    content  = <<EOF
spark.shuffle.spill                true
EOF
    filename = "config.txt"
  }

  spark_version = 3.4

  tags = merge(local.rg_tags)

}

# ------------------------------------------------------------------------------------------------------
# Deploy Synapse Role Assignments
# ------------------------------------------------------------------------------------------------------
# Assign the Synapse Workspace the Contributor role on itself.
# This allows the Synapse Workspace to manage its own resources.
# The principal_id is obtained from the current Azure client configuration.
resource "azurerm_synapse_role_assignment" "synapse_role_assignment_self" {
  synapse_workspace_id = azurerm_synapse_workspace.synapse_ws_rabo.id
  role_name            = "Synapse Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Assign the Synapse Workspace the Storage Blob Data Contributor role on the Storage Account.
# This allows Synapse to read and write data to the Storage Account.
resource "azurerm_role_assignment" "synapse_storage_access" {
  scope                = azurerm_storage_account.storage_rabo.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapse_ws_rabo.identity[0].principal_id
}


# ------------------------------------------------------------------------------------------------------
# Deploy Synapse Firewall Rule
# ------------------------------------------------------------------------------------------------------
resource "azurerm_synapse_firewall_rule" "fw_rule_rabo" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.synapse_ws_rabo.id
  # will replaced by data.http.clientIp.response_body
  start_ip_address     = trim(data.http.client_ip.response_body, "\n")
  end_ip_address       = trim(data.http.client_ip.response_body, "\n")
}