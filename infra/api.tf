# ------------------------------------------------------------------------------------------------------
# Deploy Container Registry
# ------------------------------------------------------------------------------------------------------
# This Terraform configuration file sets up an Azure Container Registry (ACR) for storing Docker images.
# It uses the azurerm provider to create the ACR and assigns the necessary role for the App Service to pull images.
# The ACR is configured with a Basic SKU, which is suitable for development and testing scenarios.
# The App Service is configured to use the ACR for its Docker image.
# The null resource is used to build and push the Docker image to the ACR.
# The Docker image is built from the API application located in the ../api directory.
# The app settings for the App Service include a Key Vault URL for secure access to secrets.
resource "azurerm_container_registry" "acr_rabo" {
  name                = var.containerRegistryName
  resource_group_name = azurerm_resource_group.rg_rabo.name
  location            = azurerm_resource_group.rg_rabo.location
  sku                 = "Basic"

  tags = merge(local.rg_tags)
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                            = azurerm_container_registry.acr_rabo.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_linux_web_app.app_service_rabo.identity[0].principal_id
  skip_service_principal_aad_check = true
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

# ------------------------------------------------------------------------------------------------------
# Deploy App Service Plan and Linux Web App
# ------------------------------------------------------------------------------------------------------
# This Terraform configuration file sets up an App Service Plan and a Linux Web App in Azure.
# The App Service Plan is configured with a Basic SKU, which is suitable for development and testing
# scenarios. The Linux Web App is configured to use a Docker image from the Azure Container Registry.
# The App Service is set to use a system-assigned managed identity for secure access to other Azure resources.
# The app settings include a Key Vault URL for secure access to secrets.
# The output provides the URL of the App Service for easy access.
resource "azurerm_service_plan" "service_plan_rabo" {
  name                = var.servicePlanName
  location            = azurerm_resource_group.rg_rabo.location
  resource_group_name = azurerm_resource_group.rg_rabo.name
  os_type             = "Linux"
  sku_name            = "B1"
  tags                = merge(local.rg_tags)
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
      docker_image_name   = "${var.restApiName}:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr_rabo.login_server}"
    }
  }

  app_settings = {
    KEYVAULT_URL = "https://kv-rabo.vault.azure.net/"
  }

  tags = merge(local.rg_tags)

  depends_on = [null_resource.docker_build_push]
}

