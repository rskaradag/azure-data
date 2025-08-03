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
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
  }
  # Configure the backend to store the Terraform state file in Azure Storage.
  # This allows for remote state management and collaboration.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstateaccountrabo"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  # Using az cli login for this scenario, add client_id, tenant_id, and subscription_id if needed.
  # That will change based on environment and authentication method.
  features {}
}
