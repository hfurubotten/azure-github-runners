resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-github-runner-${random_string.this.id}"
  location            = azurerm_resource_group.github_runner.location
  resource_group_name = azurerm_resource_group.github_runner.name

  sku               = "PerGB2018"
  retention_in_days = 30

  tags = azurerm_resource_group.github_runner.tags
}
