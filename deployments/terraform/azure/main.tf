provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg-${random_string.suffix.result}"
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                     = "sage${random_string.suffix.result}storage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  https_only               = true
  min_tls_version          = "TLS1_2"
  allow_blob_public_access = false

  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "sage-${random_string.suffix.result}-cosmos"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  enable_free_tier = true

  tags = {
    project = var.project_name
  }
}

resource "azurerm_cosmosdb_sql_database" "dev" {
  name                = "sage-dev-db"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_database" "prod" {
  name                = "sage-prod-db"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_container" "dev_containers" {
  for_each            = toset(["users", "accounts", "transactions", "plaid_tokens"])
  name                = each.key
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.dev.name
  partition_key_path  = "/userId"
}

resource "azurerm_cosmosdb_sql_container" "prod_containers" {
  for_each            = toset(["users", "accounts", "transactions", "plaid_tokens"])
  name                = each.key
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_sql_database.prod.name
  partition_key_path  = "/userId"
}

resource "azurerm_application_insights" "main" {
  name                = "sage-${random_string.suffix.result}-insights"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"
  retention_in_days   = 30

  tags = {
    project = var.project_name
  }
}

resource "azurerm_key_vault" "main" {
  name                        = "sage-${random_string.suffix.result}-kv"
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  sku_name                    = "standard"
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = true

  tags = {
    project = var.project_name
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_crypto_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_crypto_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_service_plan" "main" {
  name                = "sage-${random_string.suffix.result}-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
}

resource "azurerm_linux_function_app" "main" {
  name                = "sage-${random_string.suffix.result}-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  storage_account_name = azurerm_storage_account.main.name
  service_plan_id      = azurerm_service_plan.main.id

  site_config {
    application_stack {
      python_version = "3.11"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "COSMOS_DB_ENDPOINT"                    = azurerm_cosmosdb_account.main.endpoint
    "COSMOS_DB_KEY"                         = azurerm_cosmosdb_account.main.primary_key
    "COSMOS_DB_NAME"                        = "sage-prod-db"
    "KEY_VAULT_URL"                         = azurerm_key_vault.main.vault_uri
    "ENVIRONMENT"                           = var.environment
  }

  tags = {
    project = var.project_name
  }
}

resource "azurerm_static_site" "main" {
  name                = "sage-${random_string.suffix.result}-web"
  resource_group_name = azurerm_resource_group.main.name
  location            = "Central US" # Static Web Apps are global but require a location for the staging environments
  sku_tier            = "Free"
  sku_size            = "Free"

  tags = {
    project = var.project_name
  }
}
