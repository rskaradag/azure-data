terraform {
    # This Terraform configuration file sets up the required providers and backend for managing Azure resources.
    # It uses the azurerm provider for Azure resources, the random provider for generating random values,
    # and the null provider for executing local commands during provisioning.
    # The backend is configured to store the Terraform state file in Azure Storage for remote state management
    # and collaboration.
    # The version constraints ensure compatibility with the latest features and best practices.
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.37.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
  }
  # Configure the backend to store the Terraform state file in Azure Storage.
  # This allows for remote state management and collaboration.
  backend "azurerm" {
    resource_group_name   = "rg-tfstate"
    storage_account_name  = "tfstateaccountrabo"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}

provider "azurerm" {
# Using az cli login for this scenario, add client_id, tenant_id, and subscription_id if needed.
# That will change based on environment and authentication method.
  features {}
}

data "azurerm_client_config" "current" {
}
data "azuread_client_config" "current" {}

# This Terraform configuration file sets up a Resource Group, Storage Account, and Storage Container in Azure.
resource "azurerm_resource_group" "rabo" {
  name     = local.resourceNames.resourceGroupName
  location = var.azureRegion

  tags = merge(local.rg_tags)

  lifecycle {
    ignore_changes = [
      tags["CreatedDate"]
    ]
  }
}

# Create a Storage Account for storing data. This account is configured for hierarchical namespace (HNS) to support Data Lake Gen2 features.
# The name is generated using a random integer suffix to ensure uniqueness.
resource "azurerm_storage_account" "rabo" {
  name                     = "datastorage${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.rabo.name
  location                 = azurerm_resource_group.rabo.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}

resource "azurerm_storage_container" "container" {
  name                  = "statements"
  storage_account_name  = azurerm_storage_account.rabo.name
  container_access_type = "private"
}

# Required for uploading files to the storage account
data "azurerm_storage_account" "raboData" {
  name                = azurerm_storage_account.rabo.name
  resource_group_name = azurerm_resource_group.rabo.name
}

