terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.60.0"
    }
  }
  required_version = ">= 0.15"
}

provider "azurerm" {
  features {}
}
