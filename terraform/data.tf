# auth-mode is required to upload the file using the storage account key. could not upload using az auth login. best practices needs to be checked.
# This data source retrieves the storage account details, including the primary access key.
resource "null_resource" "upload_csv" {
  provisioner "local-exec" {
    command = <<EOT
      az storage blob upload \
        --account-name ${azurerm_storage_account.storage.name} \
        --account-key ${data.azurerm_storage_account.storage_data.primary_access_key} \
        --container-name ${azurerm_storage_container.container.name} \
        --name transactions.csv \
        --file ./data/records.csv \
        --auth-mode key 
    EOT
  }

  depends_on = [
    azurerm_storage_account.storage,
    azurerm_storage_container.container
  ]
}


