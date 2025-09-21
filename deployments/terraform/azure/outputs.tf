output "function_app_url" {
  value = azurerm_function_app.backend.default_hostname
}

output "static_web_app_url" {
  value = azurerm_static_site.frontend.default_hostname
}
