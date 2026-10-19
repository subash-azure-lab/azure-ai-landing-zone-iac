terraform {
  required_version = ">= 1.9"

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstatesubash01"
    container_name       = "tfstate"
    use_azuread_auth     = true
    # "key" (the state blob name) is supplied per environment at init:
    #   terraform init -backend-config=backend-dev.hcl
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}


