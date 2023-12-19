output "webapp_url" {
  value = azurerm_linux_web_app.azlwebapp.default_hostname
}
output "webapp_ips" {
  value = azurerm_linux_web_app.azlwebapp.outbound_ip_addresses
}