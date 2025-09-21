output "function_app_url" {
  value = azurerm_linux_function_app.main.default_hostname
}

output "static_web_app_url" {
  value = azurerm_static_web_app.main.default_host_name
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "function_app_name" {
  value = azurerm_linux_function_app.main.name
}

output "static_web_app_name" {
  value = azurerm_static_web_app.main.name
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "cosmos_db_name" {
  value = azurerm_cosmosdb_account.main.name
}

output "storage_account_name" {
  value = azurerm_storage_account.main.name
}

output "application_insights_name" {
  value = azurerm_application_insights.main.name
}

output "dev_azure_client_id" {
  value = azuread_application.monet_dev.client_id
  sensitive = false
}

output "prod_azure_client_id" {
  value = azuread_application.monet_prod.client_id
  sensitive = false
}

output "azure_tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
  sensitive = false
}
