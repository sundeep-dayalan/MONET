terraform {
  backend "azurerm" {
    resource_group_name  = "monet-tfstate-rg"
    storage_account_name = "monetstate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
