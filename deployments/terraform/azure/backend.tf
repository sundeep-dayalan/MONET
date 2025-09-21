terraform {
  backend "azurerm" {
    resource_group_name  = "sage-tfstate-rg"
    storage_account_name = "sagestate"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
