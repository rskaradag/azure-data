# ------------------------------------------------------------------------------------------------------
# Deploy data sources
# ------------------------------------------------------------------------------------------------------
# This Terraform configuration file sets up data sources for the current Azure client configuration and Azure AD client configuration.
# These data sources are used to retrieve information about the current Azure client and Azure AD client,
# which is necessary for configuring access policies and permissions in Azure Key Vault and other resources.
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}
data "http" "client_ip" {
  url = "https://api.ipify.org"
}

# ------------------------------------------------------------------------------------------------------
# Deploy resource Group
# ------------------------------------------------------------------------------------------------------
# This Terraform configuration file sets up a Resource Group, Storage Account, and Storage Container in Azure.
resource "azurerm_resource_group" "rg_rabo" {
  name     = local.resourceNames.resourceGroupName
  location = var.azureRegion

  tags = merge(local.rg_tags)

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# ------------------------------------------------------------------------------------------------------
# Deploy storage account
# ------------------------------------------------------------------------------------------------------
# Create a Storage Account for storing data. This account is configured for hierarchical namespace (HNS) to support Data Lake Gen2 features.
resource "azurerm_storage_account" "storage_rabo" {
  name                     = local.resourceNames.storageAccountName
  resource_group_name      = azurerm_resource_group.rg_rabo.name
  location                 = azurerm_resource_group.rg_rabo.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "BlobStorage"
  is_hns_enabled           = "true"

  tags = merge(local.rg_tags)
}

# ------------------------------------------------------------------------------------------------------
# Deploy container in storage account
# ------------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "container_rabo" {
  name                  = local.resourceNames.storageContainerName
  storage_account_id  = azurerm_storage_account.storage_rabo.id
  container_access_type = "private"
}

# ------------------------------------------------------------------------------------------------------
# Deploy CSV file to storage account
# ------------------------------------------------------------------------------------------------------
# This is necessary for uploading files to the storage account.
resource "azurerm_role_assignment" "role_assignment_service_principal" {
  scope                = azurerm_storage_account.storage_rabo.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# This null resource uploads a CSV file to the storage account container.
# It uses the Azure CLI to upload the file, which is useful for development and testing.
# In production, consider using a more robust solution for data ingestion.
resource "null_resource" "upload_csv" {
  provisioner "local-exec" {
    command = <<EOT
            az storage blob upload \
      --account-name ${azurerm_storage_account.storage_rabo.name} \
      --container-name ${azurerm_storage_container.container_rabo.name}\
      --name transactions.csv \
      --file ./data/records.csv \
      --auth-mode login
    EOT
  }

  depends_on = [
    azurerm_storage_container.container_rabo,
    azurerm_role_assignment.synapse_storage_access
  ]
}
