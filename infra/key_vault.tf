resource "azurerm_key_vault" "github_runner" {
  name                = "kv-gh-runner-${random_string.this.id}"
  resource_group_name = azurerm_resource_group.github_runner.name
  location            = azurerm_resource_group.github_runner.location
  sku_name            = "standard"
  tenant_id           = data.azurerm_subscription.current.tenant_id

  soft_delete_retention_days = 7
  rbac_authorization_enabled = true
}

resource "azurerm_key_vault_secret" "github_pat" {
  name         = "github-pat"
  key_vault_id = azurerm_key_vault.github_runner.id

  value = "set this later in portal"

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}
