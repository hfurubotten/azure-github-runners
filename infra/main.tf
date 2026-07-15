data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "github_runner" {
  location = "swedencentral"
  name     = "rg-github-runners-${random_string.this.id}"
}

resource "random_string" "this" {
  length = 5
  special = false
  upper = false
}
