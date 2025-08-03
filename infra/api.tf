# ------------------------------------------------------------------------------------------------------
# Deploy app service web app
# ------------------------------------------------------------------------------------------------------

resource "azurerm_service_plan" "service_plan_rabo" {
  name                = "rabo-app"
  location            = azurerm_resource_group.rg_rabo.location
  resource_group_name = azurerm_resource_group.rg_rabo.name
  os_type             = "Linux"
  sku_name            = "B1"

  tags = merge(local.rg_tags)
}

resource "azurerm_linux_web_app" "app_service_rabo" {
  name                = "rabo-service"
  location            = azurerm_resource_group.rg_rabo.location
  resource_group_name = azurerm_resource_group.rg_rabo.name
  service_plan_id = azurerm_service_plan.service_plan_rabo.id
  zip_deploy_file = "${path.module}/app.zip"

  identity {
    type = "SystemAssigned"
  }

  logs{
    application_logs {
      file_system_level = "Verbose"
    }
  }

  site_config {
    application_stack {
      python_version = "3.12"
    }
    app_command_line = "bash startup.sh"
  }

  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = "${path.module}/app.zip"
    SQL_SERVER               = "@Microsoft.KeyVault(SecretName=SQL-SERVER)"
    SQL_DB                   = "@Microsoft.KeyVault(SecretName=SQL-DB)"
    SQL_USER                 = "@Microsoft.KeyVault(SecretName=SQL-USER)"
    SQL_PASSWORD             = "@Microsoft.KeyVault(SecretName=SQL-PASSWORD)"
    KEYVAULT_URL             = "https://kv-rabo.vault.azure.net/"
  }


  tags = merge(local.rg_tags)

  depends_on = [null_resource.zip_api]
}

resource "null_resource" "zip_api" {
  triggers = {
    source_hash = filesha256("${path.module}/../api/app.py")
  }

  provisioner "local-exec" {
    command = "cd ../api && zip -r ../infra/app.zip ."
  }
}

output "app_url" {
  value = "https://${azurerm_linux_web_app.app_service_rabo.default_hostname}/invalid-transactions"
}
