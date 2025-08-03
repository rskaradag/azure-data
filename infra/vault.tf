# This Terraform configuration file sets up an Azure Key Vault for secure storage of secrets.
# The Key Vault is configured with a system-assigned managed identity for secure access to secrets.
resource "azurerm_key_vault" "kv" {
  name                     = "kv-rabo"
  location                 = azurerm_resource_group.rg_rabo.location
  resource_group_name      = azurerm_resource_group.rg_rabo.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false

  # It allows the Synapse Workspace to access secrets stored in the Key Vault. Least privilege principle is applied.
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_synapse_workspace.synapse_ws_rabo.identity[0].principal_id

    secret_permissions  = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
    key_permissions     = ["Get", "List", "Update", "Delete", "Recover", "Create", "GetRotationPolicy", "SetRotationPolicy", "Verify", "Release", "WrapKey", "UnwrapKey", "Decrypt", "Encrypt"]
    storage_permissions = ["Get", "List", "Set", "Delete", "Recover", "RegenerateKey", "Backup", "Restore", "Purge"]
  }

  # This is the identity of the App Service within Azure Active Directory (Azure AD).
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_web_app.app_service_rabo.identity[0].principal_id

    secret_permissions = ["Get", "List"]
  }

  # This is the identity of the Service Principal within Azure Active Directory (Azure AD).
  # Services that rely on Azure AD-based access control — such as Azure Key Vault — expect this object_id when assigning permissions.
  # It is required when granting access to secrets, including permissions like get, set, list, and delete.
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azuread_client_config.current.object_id

    secret_permissions  = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
    key_permissions     = ["Get", "List", "Update", "Delete", "Recover", "Create", "GetRotationPolicy", "SetRotationPolicy", "Verify", "Release", "WrapKey", "UnwrapKey", "Decrypt", "Encrypt"]
    storage_permissions = ["Get", "List", "Set", "Delete", "Recover", "RegenerateKey", "Backup", "Restore", "Purge"]
  }

}

# ------------------------------------------------------------------------------------------------------
# Store SQL Server and Database credentials in Key Vault.
# ------------------------------------------------------------------------------------------------------
resource "azurerm_key_vault_secret" "sql_server" {
  name         = "SQL-SERVER"
  value        = var.SQLServerName
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "sql_db" {
  name         = "SQL-DATABASE"
  value        = var.SQLDBName
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "sql_user" {
  name         = "SQL-USER"
  value        = var.SQLAdminUsername
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_key_vault_secret" "sql_pass" {
  name         = "SQL-PASSWORD"
  value        = var.SQLAdminPassword
  key_vault_id = azurerm_key_vault.kv.id
}
