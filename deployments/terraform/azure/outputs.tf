output "function_app_url" {
  value = azurerm_linux_function_app.main.default_hostname
}

output "static_web_app_url" {
  value = azurerm_static_site.main.default_hostname
}

output "resource_group_name" {
  value = azurerm_resource_group.main.name
}
