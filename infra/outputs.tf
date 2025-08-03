output "resource_group_name" {
  value = azurerm_resource_group.rg_rabo.name
}

output "synapse_workspace_name" {
  value = azurerm_synapse_workspace.synapse_ws_rabo.name
}

output "synapse_identity" {
  value = azurerm_synapse_workspace.synapse_ws_rabo.identity[0].principal_id
}