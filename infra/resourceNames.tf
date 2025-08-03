# naming structure according to CAF
locals {
  resourceNames = {
    resourceGroupName     = join("-", [local.azPrefix.resource_group, local.baseName])
    sysnapseWorkspaceName = join("-", [local.azPrefix.azure_synapse_analytics_workspaces, local.baseName])
    sqlServerName         = join("-", [local.azPrefix.azure_sql_database_server, local.baseName])
    sqlDatabaseName       = join("-", [local.azPrefix.azure_sql_database, local.baseName])
    synapseSparkPoolName  = join("", [local.azPrefix.azure_synapse_analytics_spark_pool, var.applicationName])
    storageAccountName    = join("", [local.azPrefix.storage_account, var.applicationName, var.environment, var.azureRegion])
    storageContainerName  = join("-", ["cnt", local.baseName])
    synapseFilesytemName  = join("-", ["fs", local.baseName])
  }

  rendered_pipeline_json = templatefile("${path.module}/pipelines/validate_pipeline.json.tpl", {
    pipeline_name   = "validate-csv-pipeline"
    notebook_name   = "validate-csv"
    spark_pool_name = azurerm_synapse_spark_pool.spark_pool_rabo.name
  })

}