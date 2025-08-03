# ------------------------------------------------------------------------------------------------------
# Deploy app service web app
# ------------------------------------------------------------------------------------------------------

resource "azurerm_container_registry" "acr_rabo" {
  name                = var.containerRegistryName
  resource_group_name = azurerm_resource_group.rg_rabo.name
  location            = azurerm_resource_group.rg_rabo.location
  sku                 = "Basic"

  tags = merge(local.rg_tags)
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr_rabo.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.app_service_rabo.identity[0].principal_id
}

resource "null_resource" "docker_build_push" {
  triggers = {
    source_hash = filesha256("${path.module}/../api/app.py")
  }

  provisioner "local-exec" {
    command = <<EOT
      az acr login --name ${azurerm_container_registry.acr_rabo.name}
      docker build -t ${azurerm_container_registry.acr_rabo.login_server}/${var.restApiName}:latest ../api
      docker push ${azurerm_container_registry.acr_rabo.login_server}/${var.restApiName}:latest
    EOT
  }

  depends_on = [azurerm_container_registry.acr_rabo]
}


resource "azurerm_service_plan" "service_plan_rabo" {
  name                =  var.servicePlanName
  location            = azurerm_resource_group.rg_rabo.location
  resource_group_name = azurerm_resource_group.rg_rabo.name
  os_type             = "Linux"
  sku_name            = "B1"

  tags = merge(local.rg_tags)
}

resource "azurerm_linux_web_app" "app_service_rabo" {
  name                = var.appServiceName
  location            = azurerm_resource_group.rg_rabo.location
  resource_group_name = azurerm_resource_group.rg_rabo.name
  service_plan_id     = azurerm_service_plan.service_plan_rabo.id

  identity {
    type = "SystemAssigned"
  }

  logs {
    application_logs {
      file_system_level = "Verbose"
    }
  }

  site_config {
    application_stack {
      docker_image_name   = "${azurerm_container_registry.acr_rabo.login_server}/${var.restApiName}:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr_rabo.login_server}"
    }
  }

  app_settings = {
    KEYVAULT_URL = "https://kv-rabo.vault.azure.net/"
    SQL_SERVER   = "@Microsoft.KeyVault(SecretName=SQL-SERVER)"
    SQL_DB       = "@Microsoft.KeyVault(SecretName=SQL-DB)"
    SQL_USER     = "@Microsoft.KeyVault(SecretName=SQL-USER)"
    SQL_PASSWORD = "@Microsoft.KeyVault(SecretName=SQL-PASSWORD)"
  }

  tags = merge(local.rg_tags)

  depends_on = [null_resource.docker_build_push]
}

# resource "null_resource" "zip_api" {
#   triggers = {
#     source_hash = filesha256("${path.module}/../api/app.py")
#   }

#   provisioner "local-exec" {
#     command = "cd ../api && zip -r ../infra/app.zip ."
#   }
# }

output "app_url" {
  value = "https://${azurerm_linux_web_app.app_service_rabo.default_hostname}/heatlhcheck"
}
