resource "azurerm_container_registry" "this" {
  name                = random_string.this.id
  resource_group_name = azurerm_resource_group.github_runner.name
  location            = azurerm_resource_group.github_runner.location
  sku                 = "Basic"
  admin_enabled       = false

  anonymous_pull_enabled   = false
  data_endpoint_enabled    = false
  retention_policy_in_days = 0
}
