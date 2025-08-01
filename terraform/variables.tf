variable "azureRegion" {
  type = string
  description = "Azure region where resources will be created"
}
variable "applicationName" {
  type = string
  description = "Please provide a name for the application. This will be used to generate resource names."
}
variable "environment" {
  type = string
  description = "Please provide the environment name. This will be used to generate resource names."

  validation {
    condition = contains(["dev", "test", "prod"], lower(var.environment))
    error_message = "Environment must be one of: dev, test, prod."
  }
}


# GitHub Authentication
# variable "githubToken" {
#   # Set using environment variable TF_VAR_githubToken
#   type        = string
#   description = "Please enter a PAT or OAuth token for GitHub authentication."
#   sensitive   = true
# }



variable "synapse_sql_admin_password" {
  description = "Synapse SQL Server admin password"
  type        = string
  sensitive   = true
}
variable "synapse_sql_admin_username" {

}




variable "sql_admin_password" {
  description = "SQL Server admin password"
  type        = string
  sensitive   = true
}
variable "sql_admin_username" {

}
variable "sqlserver_name" {

}
variable "db_name" {

}



