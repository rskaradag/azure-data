output "resource_group_name" {
  value = azurerm_resource_group.rabo.name
}

output "synapse_workspace" {
  value = azurerm_synapse_workspace.synapseRabo.name
}
