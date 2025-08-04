variable "azureRegion" {
  type        = string
  description = "Azure region where resources will be created"
}
variable "applicationName" {
  type        = string
  description = "Please provide a name for the application. This will be used to generate resource names."
}
variable "environment" {
  type        = string
  description = "Please provide the environment name. This will be used to generate resource names."

  validation {
    condition     = contains(["dev", "test", "prod"], lower(var.environment))
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "synapseSQLAdminPassword" {
  description = "Synapse SQL Server admin password"
  type        = string
  sensitive   = true
}
variable "synapseSQLAdminUsername" {

}
variable "synapseRepoRootFolder" {
  description = "Root folder for Synapse repository"
  type        = string
}



variable "SQLAdminPassword" {
  description = "SQL Server admin password"
  type        = string
  sensitive   = true
}
variable "SQLAdminUsername" {

}
variable "SQLServerName" {

}
variable "SQLDBName" {

}

variable "containerRegistryName" {
  description = "Name of the Azure Container Registry"
  type        = string
}

variable "restApiName" {
  description = "Name of the REST API"
  type        = string
}
variable "appServiceName" {
  description = "Name of the Service Name"
  type        = string
}

variable "servicePlanName" {
  description = "Name of the App Service Plan"
  type        = string
}


variable "ARM_CLIENT_ID" {
  type      = string
  sensitive = true
}
variable "ARM_TENANT_ID" {
  type      = string
  sensitive = true
}
variable "ARM_CLIENT_SECRET" {
  type      = string
  sensitive = true
}