terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.79"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.9.0"
    }
  }
}

provider "azapi" {}
provider "azurerm" {
  features {}

  storage_use_azuread = true
}
