provider "azurerm" {
  features {}
  skip_provider_registration = true
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
  name                     = "monet${random_string.suffix.result}storage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  enable_https_traffic_only = true
  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled = false

  tags = {
    project     = var.project_name
    environment = var.environment
  }
}

resource "azurerm_cosmosdb_account" "main" {
  name                = "monet-${random_string.suffix.result}-cosmos"
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

  free_tier_enabled = true

  tags = {
    project = var.project_name
  }
}

resource "azurerm_cosmosdb_sql_database" "dev" {
  name                = "monet-dev-db"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  throughput          = 400
}

resource "azurerm_cosmosdb_sql_database" "prod" {
  name                = "monet-prod-db"
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
  name                = "monet-${random_string.suffix.result}-insights"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  application_type    = "web"
  retention_in_days   = 30

  tags = {
    project = var.project_name
  }
}

resource "azurerm_key_vault" "main" {
  name                        = "monet-${random_string.suffix.result}-kv"
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

# Azure AD App Registrations for dev and prod environments
resource "azuread_application" "monet_dev" {
  display_name     = "monet-dev-app"
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"

  web {
    redirect_uris = [
      "https://${azurerm_linux_function_app.main.default_hostname}/api/v1/auth/oauth/microsoft/callback",
      "https://${azurerm_static_web_app.main.default_host_name}/auth/callback",
      "http://localhost:5173/auth/callback",
      "http://localhost:8000/api/v1/auth/oauth/microsoft/callback"
    ]
    
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }

    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
      type = "Scope"
    }

    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
      type = "Scope"
    }
  }
}

resource "azuread_application" "monet_prod" {
  display_name     = "monet-prod-app"
  sign_in_audience = "AzureADandPersonalMicrosoftAccount"

  web {
    redirect_uris = [
      "https://${azurerm_linux_function_app.main.default_hostname}/api/v1/auth/oauth/microsoft/callback",
      "https://${azurerm_static_web_app.main.default_host_name}/auth/callback",
      "http://localhost:5173/auth/callback",
      "http://localhost:8000/api/v1/auth/oauth/microsoft/callback"
    ]
    
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }

    resource_access {
      id   = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
      type = "Scope"
    }

    resource_access {
      id   = "14dad69e-099b-42c9-810b-d002981feec1" # profile
      type = "Scope"
    }
  }
}

# Service Principals for the Azure AD apps
resource "azuread_service_principal" "monet_dev" {
  client_id = azuread_application.monet_dev.client_id
}

resource "azuread_service_principal" "monet_prod" {
  client_id = azuread_application.monet_prod.client_id
}

# Client secrets for the Azure AD apps
resource "azuread_application_password" "monet_dev" {
  application_id = azuread_application.monet_dev.id
  display_name   = "monet-dev-client-secret"
  end_date       = timeadd(timestamp(), "17520h") # 2 years
}

resource "azuread_application_password" "monet_prod" {
  application_id = azuread_application.monet_prod.id
  display_name   = "monet-prod-client-secret"
  end_date       = timeadd(timestamp(), "17520h") # 2 years
}

data "azurerm_role_definition" "kv_secrets_officer" {
  name = "Key Vault Secrets Officer"
}

data "azurerm_role_definition" "kv_crypto_user" {
  name = "Key Vault Crypto User"
}

data "azurerm_role_definition" "kv_crypto_officer" {
  name = "Key Vault Crypto Officer"
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_id   = data.azurerm_role_definition.kv_secrets_officer.id
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_crypto_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_id   = data.azurerm_role_definition.kv_crypto_user.id
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_crypto_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_id   = data.azurerm_role_definition.kv_crypto_officer.id
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_service_plan" "main" {
  name                = "monet-${random_string.suffix.result}-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "Y1" # Consumption plan
}

resource "azurerm_linux_function_app" "main" {
  name                = "monet-${random_string.suffix.result}-api"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  storage_account_name = azurerm_storage_account.main.name
  service_plan_id      = azurerm_service_plan.main.id

  site_config {
    application_stack {
      python_version = "3.11"
    }
    
    cors {
      allowed_origins = [
        "https://${azurerm_static_web_app.main.default_host_name}",
        "https://monet-${random_string.suffix.result}-api.azurewebsites.net",
        "http://localhost:5173",
        "http://localhost:3000"
      ]
      support_credentials = true
    }
  }

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "FUNCTIONS_WORKER_RUNTIME"              = "python"
    "PYTHON_ENABLE_GUNICORN_MULTIPROCESSING" = "1"
    "COSMOS_DB_ENDPOINT"                    = azurerm_cosmosdb_account.main.endpoint
    "COSMOS_DB_NAME"                        = "monet-prod-db"
    "KEY_VAULT_URL"                         = azurerm_key_vault.main.vault_uri
    "ENVIRONMENT"                           = var.environment
    "AzureWebJobsStorage__accountName"      = azurerm_storage_account.main.name
    
    # Azure AD Configuration (Key Vault references)
    "AZURE_CLIENT_ID"                       = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=prod-azure-client-id)"
    "AZURE_CLIENT_SECRET"                   = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=prod-azure-client-secret)"
    "AZURE_TENANT_ID"                       = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=prod-azure-tenant-id)"
    "AZURE_REDIRECT_URI"                    = "https://monet-${random_string.suffix.result}-api.azurewebsites.net/api/v1/auth/oauth/microsoft/callback"
    
    # App Configuration
    "PROJECT_NAME"                          = "MONET API"
    "VERSION"                               = "2.0.2"
    "API_V1_PREFIX"                         = "/api/v1"
    "DEBUG"                                 = "false"
    "ALGORITHM"                             = "HS256"
    "ACCESS_TOKEN_EXPIRE_MINUTES"           = "1440"
    "FRONTEND_URL"                          = "https://${azurerm_static_web_app.main.default_host_name}"
    "ALLOWED_HOSTS"                         = "${azurerm_static_web_app.main.default_host_name},monet-${random_string.suffix.result}-api.azurewebsites.net"
    "ALLOWED_ORIGINS"                       = "https://${azurerm_static_web_app.main.default_host_name},https://monet-${random_string.suffix.result}-api.azurewebsites.net,http://localhost:5173,http://localhost:3000"
    "LOG_LEVEL"                             = "INFO"
    "SESSION_SECRET_KEY"                    = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.main.name};SecretName=session-secret-key)"
  }

  tags = {
    project = var.project_name
  }
}

resource "azurerm_static_web_app" "main" {
  name                = "monet-${random_string.suffix.result}-web"
  resource_group_name = azurerm_resource_group.main.name
  location            = "Central US"
  sku_tier            = "Free"
  sku_size            = "Free"

  tags = {
    project = var.project_name
  }
}

# Role assignments for Function App managed identity
data "azurerm_role_definition" "cosmos_contributor" {
  name = "DocumentDB Account Contributor"
}

data "azurerm_role_definition" "storage_blob_data_owner" {
  name = "Storage Blob Data Owner"
}

resource "azurerm_role_assignment" "function_cosmos_access" {
  scope                = azurerm_cosmosdb_account.main.id
  role_definition_id   = data.azurerm_role_definition.cosmos_contributor.id
  principal_id         = azurerm_linux_function_app.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "function_storage_access" {
  scope                = azurerm_storage_account.main.id
  role_definition_id   = data.azurerm_role_definition.storage_blob_data_owner.id
  principal_id         = azurerm_linux_function_app.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "function_kv_secrets_access" {
  scope                = azurerm_key_vault.main.id
  role_definition_id   = data.azurerm_role_definition.kv_secrets_officer.id
  principal_id         = azurerm_linux_function_app.main.identity[0].principal_id
}

# Key Vault Secrets for Azure AD applications
resource "azurerm_key_vault_secret" "dev_azure_client_id" {
  name         = "dev-azure-client-id"
  value        = azuread_application.monet_dev.client_id
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "dev_azure_client_secret" {
  name         = "dev-azure-client-secret"
  value        = azuread_application_password.monet_dev.value
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "dev_azure_tenant_id" {
  name         = "dev-azure-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "prod_azure_client_id" {
  name         = "prod-azure-client-id"
  value        = azuread_application.monet_prod.client_id
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "prod_azure_client_secret" {
  name         = "prod-azure-client-secret"
  value        = azuread_application_password.monet_prod.value
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "prod_azure_tenant_id" {
  name         = "prod-azure-tenant-id"
  value        = data.azurerm_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

# Generate session secret key
resource "random_password" "session_secret" {
  length  = 32
  special = true
}

resource "azurerm_key_vault_secret" "session_secret_key" {
  name         = "session-secret-key"
  value        = base64encode(random_password.session_secret.result)
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [azurerm_role_assignment.kv_secrets_officer]
}

# Cryptographic key for encryption and JWT signing
resource "azurerm_key_vault_key" "secrets_encryption" {
  name         = "secrets-encryption-key"
  key_vault_id = azurerm_key_vault.main.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["encrypt", "decrypt", "sign", "verify"]
  depends_on   = [azurerm_role_assignment.kv_crypto_officer]
}
