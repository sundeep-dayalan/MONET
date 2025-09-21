#!/bin/bash

# MONET Financial Management App - Full Azure Deployment
# This script is designed to be executed by an ARM deployment script resource.

set -e

# Arguments passed from ARM template
PROJECT_NAME="$1"
STORAGE_ACCOUNT_NAME="$2"
COSMOS_ACCOUNT_NAME="$3"
APP_INSIGHTS_NAME="$4"
KEY_VAULT_NAME="$5"
FUNCTION_APP_NAME="$6"
STATIC_WEB_APP_NAME="$7"

# Get current resource group name
RESOURCE_GROUP=$(az group show --name "$AZ_RESOURCE_GROUP" --query name -o tsv)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Variables to store Azure AD credentials for each environment
AZURE_PROD_CLIENT_ID=""
AZURE_PROD_CLIENT_SECRET=""
AZURE_AD_TENANT_ID=""

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}
print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN} $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to retry Azure CLI commands
retry_az_command() {
    local max_attempts=${1:-3}
    local delay=${2:-5}
    local operation_name=${3:-"Azure operation"}
    shift 3
    local cmd=("$@")
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if "${cmd[@]}" 2>/dev/null; then
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                local wait_time=$((delay * attempt))
                print_warning "$operation_name failed. Retrying in ${wait_time}s..."
                sleep $wait_time
            else
                print_error "$operation_name failed after $max_attempts attempts."
                return 1
            fi
        fi
        ((attempt++))
    done
}

# Step 1: Create or Update Azure AD App Registration
create_azure_ad_app() {
    print_header "STEP 1: AZURE AD APP REGISTRATION"
    
    local frontend_url="https://$(echo $STATIC_WEB_APP_NAME | tr '[:upper:]' '[:lower:]').azurestaticapps.net"
    local backend_url="https://${FUNCTION_APP_NAME}.azurewebsites.net"
    
    AZURE_AD_TENANT_ID=$(az account show --query tenantId --output tsv)
    
    local app_name="${PROJECT_NAME}-prod-app"
    local client_id=$(az ad app list --display-name "$app_name" --query "[?displayName=='$app_name'].appId" -o tsv 2>/dev/null)
    
    if [ -n "$client_id" ]; then
        print_warning "Found existing app registration. Reusing..."
    else
        print_status "No existing app found. Creating a new one..."
        client_id=$(az ad app create \
            --display-name "$app_name" \
            --sign-in-audience "AzureADandPersonalMicrosoftAccount" \
            --query appId \
            --output tsv)
        print_success "New app created with Client ID: $client_id"
        sleep 15
    fi
    
    AZURE_PROD_CLIENT_ID="$client_id"
    
    print_status "Updating redirect URIs for Azure AD app..."
    retry_az_command 3 10 "Update Azure AD app configuration" \
        az ad app update \
        --id "$client_id" \
        --web-redirect-uris "${backend_url}/api/v1/auth/oauth/microsoft/callback" "${frontend_url}/auth/callback" "http://localhost:5173/auth/callback" "http://localhost:8000/api/v1/auth/oauth/microsoft/callback" \
        --enable-access-token-issuance true \
        --enable-id-token-issuance true

    print_status "Creating a new client secret..."
    local client_secret=$(az ad app credential reset \
        --id "$client_id" \
        --display-name "${PROJECT_NAME}-prod-client-secret" \
        --years 2 \
        --query password \
        --output tsv)

    if [ -z "$client_secret" ]; then
        print_error "Client secret creation failed."
        exit 1
    fi
    AZURE_PROD_CLIENT_SECRET="$client_secret"

    print_success "Azure AD app registration and secret creation completed!"
}

# Step 2: Setup secrets in Key Vault
setup_secrets() {
    print_header "STEP 2: KEY VAULT SECRETS"
    print_warning "Waiting for Key Vault permissions to propagate..."
    sleep 15

    local secrets=(
        "prod-azure-client-id:$AZURE_PROD_CLIENT_ID"
        "prod-azure-client-secret:$AZURE_PROD_CLIENT_SECRET"
        "prod-azure-tenant-id:$AZURE_AD_TENANT_ID"
        "session-secret-key:$(openssl rand -base64 32)"
    )

    for secret_pair in "${secrets[@]}"; do
        local secret_name=$(echo "$secret_pair" | cut -d: -f1)
        local secret_value=$(echo "$secret_pair" | cut -d: -f2-)
        
        if [[ "$secret_name" == "session-secret-key" ]]; then
            if az keyvault secret show --vault-name "$KEY_VAULT_NAME" --name "$secret_name" --output none >/dev/null 2>&1; then
                print_status "Secret '$secret_name' already exists, skipping creation to preserve data"
                continue
            fi
        fi

        retry_az_command 3 5 "Set secret $secret_name" \
            az keyvault secret set \
            --vault-name "$KEY_VAULT_NAME" \
            --name "$secret_name" \
            --value "$secret_value"
        print_status "Set secret: $secret_name"
    done

    print_status "Creating cryptographic key for encryption..."
    if ! az keyvault key show --vault-name "$KEY_VAULT_NAME" --name "secrets-encryption-key" >/dev/null 2>&1; then
        retry_az_command 3 10 "Create cryptographic key secrets-encryption-key" \
            az keyvault key create \
            --vault-name "$KEY_VAULT_NAME" \
            --name "secrets-encryption-key" \
            --kty RSA \
            --size 2048 \
            --ops encrypt decrypt sign verify
        print_success "Cryptographic key created."
    fi
    print_success "Secrets configured!"
}

# Step 3: Configure Function App settings
configure_function_app() {
    print_header "STEP 3: FUNCTION APP CONFIGURATION"
    print_status "Configuring Function App settings..."
    
    local cosmos_key=$(az cosmosdb keys list --name "$COSMOS_ACCOUNT_NAME" --resource-group "$RESOURCE_GROUP" --query primaryMasterKey -o tsv)
    local cosmos_endpoint="https://${COSMOS_ACCOUNT_NAME}.documents.azure.com:443/"
    local insights_connection=$(az monitor app-insights component show --app "$APP_INSIGHTS_NAME" --resource-group "$RESOURCE_GROUP" --query connectionString -o tsv)
    local key_vault_url="https://${KEY_VAULT_NAME}.vault.azure.net/"
    local static_web_app_hostname=$(az staticwebapp show --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" --query defaultHostname -o tsv 2>/dev/null)
    local frontend_url="https://${static_web_app_hostname}"
    
    retry_az_command 3 10 "Configure Function App app settings" \
        az functionapp config appsettings set \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --settings \
            "COSMOS_DB_ENDPOINT=$cosmos_endpoint" \
            "COSMOS_DB_KEY=$cosmos_key" \
            "COSMOS_DB_NAME=${PROJECT_NAME}-prod-db" \
            "AZURE_CLIENT_ID=@Microsoft.KeyVault(VaultName=${KEY_VAULT_NAME};SecretName=prod-azure-client-id)" \
            "AZURE_CLIENT_SECRET=@Microsoft.KeyVault(VaultName=${KEY_VAULT_NAME};SecretName=prod-azure-client-secret)" \
            "AZURE_TENANT_ID=@Microsoft.KeyVault(VaultName=${KEY_VAULT_NAME};SecretName=prod-azure-tenant-id)" \
            "KEY_VAULT_URL=$key_vault_url" \
            "ENVIRONMENT=prod" \
            "APPLICATIONINSIGHTS_CONNECTION_STRING=$insights_connection" \
            "FUNCTIONS_WORKER_RUNTIME=node" \
            "AZURE_REDIRECT_URI=https://${FUNCTION_APP_NAME}.azurewebsites.net/api/v1/auth/oauth/microsoft/callback" \
            "PROJECT_NAME=MONET API" \
            "FRONTEND_URL=$frontend_url" \
            "ALLOWED_ORIGINS=$frontend_url,https://${FUNCTION_APP_NAME}.azurewebsites.net,http://localhost:5173,http://localhost:3000" \
            "SESSION_SECRET_KEY=@Microsoft.KeyVault(VaultName=${KEY_VAULT_NAME};SecretName=session-secret-key)"
    
    print_status "Granting Function App access to Key Vault..."
    local function_app_principal_id=$(az functionapp identity show \
        --name "$FUNCTION_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query principalId -o tsv)
    
    if [ -n "$function_app_principal_id" ]; then
        print_status "Granting Key Vault Secrets User role..."
        retry_az_command 3 5 "Grant Key Vault Secrets User role" \
            az role assignment create \
            --role "Key Vault Secrets User" \
            --assignee "$function_app_principal_id" \
            --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME"
    fi
    print_success "Function App configured!"
}

# Step 4: Deploy backend code
deploy_backend() {
    print_header "STEP 4: BACKEND DEPLOYMENT"
    print_status "Deploying backend code to Function App..."
    
    cd packages/core
    
    print_status "Installing backend dependencies..."
    npm install
    
    print_status "Building backend..."
    npm run build
    
    print_status "Zipping and deploying to Azure Function App: $FUNCTION_APP_NAME"
    zip -r ../../dist.zip .
    
    az functionapp deployment source config-zip \
        --resource-group "$RESOURCE_GROUP" \
        --name "$FUNCTION_APP_NAME" \
        --src "../../dist.zip"
    
    print_success "Backend deployed successfully!"
    
    cd ../..
}

# Step 5: Deploy frontend code
deploy_frontend() {
    print_header "STEP 5: FRONTEND DEPLOYMENT"
    
    print_status "Deploying frontend code to Static Web App..."
    
    cd packages/client
    
    print_status "Installing frontend dependencies..."
    npm install
    
    print_status "Building frontend..."
    npm run build
    
    print_status "Getting Static Web App deployment token..."
    local deployment_token=$(az staticwebapp secrets list \
        --name "$STATIC_WEB_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.apiKey" -o tsv)
    
    if [ -n "$deployment_token" ]; then
        print_status "Deploying to Azure Static Web App: $STATIC_WEB_APP_NAME"
        npx @azure/static-web-apps-cli deploy \
            --app-location "dist" \
            --output-location "dist" \
            --deployment-token "$deployment_token"
    else
        print_error "Could not retrieve deployment token. Manual deployment may be required."
        exit 1
    fi
    
    print_success "Frontend deployed successfully!"
    
    cd ../..
}

# Final summary
display_summary() {
    print_header "🎉 DEPLOYMENT COMPLETED SUCCESSFULLY!"
    
    local static_web_app_url=$(az staticwebapp show --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP" --query defaultHostname -o tsv)
    local function_app_url="https://${FUNCTION_APP_NAME}.azurewebsites.net"
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "                        DEPLOYMENT SUMMARY"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    print_success "All Azure resources have been created and configured!"
    echo ""
    echo "🔗 APPLICATION URLS:"
    echo "   Frontend:  https://${static_web_app_url}"
    echo "   Backend:   $function_app_url"
    echo ""
    print_success "Your MONET Financial Management App is ready! 🎯"
}

# Error handling
handle_error() {
    local exit_code=$?
    print_error "Deployment failed at step: $CURRENT_STEP"
    print_error "Exit code: $exit_code"
    exit $exit_code
}

# Main execution
main() {
    trap handle_error ERR

    CURRENT_STEP="Azure AD App Registration"; create_azure_ad_app
    CURRENT_STEP="Key Vault Secrets"; setup_secrets
    CURRENT_STEP="Function App Configuration"; configure_function_app
    CURRENT_STEP="Backend Deployment"; deploy_backend
    CURRENT_STEP="Frontend Deployment"; deploy_frontend
    
    display_summary
}

# Run the main function
main "$@"