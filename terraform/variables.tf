variable "location" {
  default = "northeurope"
}
variable "resource_group_name" {
  default = "rg-data-demo"
}



variable "synapse_sql_admin_password" {
  description = "Synapse SQL Server admin password"
  type        = string
  sensitive   = true
}
variable "synapse_sql_admin_username" {
  default = "synapseadmin"
}



variable "sql_admin_password" {
  description = "SQL Server admin password"
  type        = string
  sensitive   = true
}
variable "sqlserver_name" {
  default = "rabosqlserver"
}
variable "db_name" {
  default = "rabodb"
}