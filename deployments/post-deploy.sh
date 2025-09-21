#!/bin/bash

# MONET Post-Deployment Automation Script
# This script handles code deployment after Azure infrastructure is provisioned
# Run this after the ARM template deployment completes

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get deployment outputs from Azure
get_deployment_outputs() {
    local resource_group="$1"
    local deployment_name="$2"
    
    print_status "Retrieving deployment outputs..."
    
    # Get outputs from the ARM template deployment
    FUNCTION_APP_NAME=$(az deployment group show \
        --resource-group "$resource_group" \
        --name "$deployment_name" \
        --query "properties.outputs.functionAppName.value" \
        --output tsv 2>/dev/null || echo "")
    
    STATIC_WEB_APP_NAME=$(az deployment group show \
        --resource-group "$resource_group" \
        --name "$deployment_name" \
        --query "properties.outputs.staticWebAppName.value" \
        --output tsv 2>/dev/null || echo "")
    
    FUNCTION_APP_URL=$(az deployment group show \
        --resource-group "$resource_group" \
        --name "$deployment_name" \
        --query "properties.outputs.functionAppUrl.value" \
        --output tsv 2>/dev/null || echo "")
    
    STATIC_WEB_APP_URL=$(az deployment group show \
        --resource-group "$resource_group" \
        --name "$deployment_name" \
        --query "properties.outputs.staticWebAppUrl.value" \
        --output tsv 2>/dev/null || echo "")
}

# Function to deploy backend code
deploy_backend() {
    print_status "Deploying backend code to Function App..."
    
    if [ -z "$FUNCTION_APP_NAME" ]; then
        print_error "Function App name not found in deployment outputs"
        return 1
    fi
    
    # Navigate to backend directory
    cd packages/core
    
    # Install dependencies and build
    print_status "Installing backend dependencies..."
    npm install
    
    print_status "Building backend..."
    npm run build
    
    # Deploy to Function App
    print_status "Deploying to Azure Function App: $FUNCTION_APP_NAME"
    az functionapp deployment source config-zip \
        --resource-group "$RESOURCE_GROUP" \
        --name "$FUNCTION_APP_NAME" \
        --src "dist.zip" || {
        print_warning "Zip deployment failed, trying alternative method..."
        
        # Alternative: Direct deployment
        func azure functionapp publish "$FUNCTION_APP_NAME" --python
    }
    
    print_success "Backend deployed successfully!"
    print_success "API URL: $FUNCTION_APP_URL"
    
    cd ../..
}

# Function to deploy frontend code
deploy_frontend() {
    print_status "Deploying frontend code to Static Web App..."
    
    if [ -z "$STATIC_WEB_APP_NAME" ]; then
        print_error "Static Web App name not found in deployment outputs"
        return 1
    fi
    
    # Navigate to frontend directory
    cd packages/client
    
    # Install dependencies and build
    print_status "Installing frontend dependencies..."
    npm install
    
    print_status "Building frontend..."
    npm run build
    
    # Get deployment token for Static Web App
    print_status "Getting Static Web App deployment token..."
    DEPLOYMENT_TOKEN=$(az staticwebapp secrets list \
        --name "$STATIC_WEB_APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "properties.apiKey" \
        --output tsv)
    
    if [ -n "$DEPLOYMENT_TOKEN" ]; then
        # Deploy using SWA CLI
        print_status "Deploying to Azure Static Web App: $STATIC_WEB_APP_NAME"
        npx @azure/static-web-apps-cli deploy \
            --app-location "." \
            --output-location "dist" \
            --deployment-token "$DEPLOYMENT_TOKEN"
    else
        print_warning "Could not retrieve deployment token, using alternative method..."
        # Alternative: GitHub Actions will handle this automatically
        print_status "Static Web App will be deployed automatically via GitHub Actions"
    fi
    
    print_success "Frontend deployment initiated!"
    print_success "App URL: $STATIC_WEB_APP_URL"
    
    cd ../..
}

# Function to configure Azure AD applications
configure_azure_ad() {
    print_status "Setting up Azure AD application registrations..."
    
    # This is a manual step that requires admin consent
    print_warning "Azure AD app registration requires manual configuration:"
    print_warning "1. Go to Azure Portal > Azure Active Directory > App registrations"
    print_warning "2. Create applications for dev and prod environments"
    print_warning "3. Configure redirect URIs for your deployed URLs"
    print_warning "4. Add client secrets to Key Vault"
    print_warning "5. Grant admin consent for required permissions"
    
    echo
    print_status "Your deployment URLs for Azure AD configuration:"
    echo "Frontend URL: $STATIC_WEB_APP_URL"
    echo "Backend URL: $FUNCTION_APP_URL"
    echo
}

# Function to validate deployment
validate_deployment() {
    print_status "Validating deployment..."
    
    # Check if Function App is running
    if [ -n "$FUNCTION_APP_URL" ]; then
        print_status "Checking Function App health..."
        if curl -s "$FUNCTION_APP_URL/api/health" >/dev/null 2>&1; then
            print_success "Function App is responding"
        else
            print_warning "Function App may still be starting up"
        fi
    fi
    
    # Check if Static Web App is accessible
    if [ -n "$STATIC_WEB_APP_URL" ]; then
        print_status "Checking Static Web App..."
        if curl -s "$STATIC_WEB_APP_URL" >/dev/null 2>&1; then
            print_success "Static Web App is accessible"
        else
            print_warning "Static Web App may still be deploying"
        fi
    fi
}

# Main deployment function
main() {
    echo "🚀 MONET Post-Deployment Automation"
    echo "======================================"
    echo
    
    # Check prerequisites
    print_status "Checking prerequisites..."
    
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! command_exists npm; then
        print_error "Node.js/npm is not installed. Please install it first."
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show >/dev/null 2>&1; then
        print_error "Please log in to Azure CLI first: az login"
        exit 1
    fi
    
    # Get parameters
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <resource-group> <deployment-name>"
        echo "Example: $0 monet-rg-12345678 azuredeploy"
        exit 1
    fi
    
    RESOURCE_GROUP="$1"
    DEPLOYMENT_NAME="$2"
    
    print_status "Resource Group: $RESOURCE_GROUP"
    print_status "Deployment Name: $DEPLOYMENT_NAME"
    echo
    
    # Get deployment information
    get_deployment_outputs "$RESOURCE_GROUP" "$DEPLOYMENT_NAME"
    
    if [ -z "$FUNCTION_APP_NAME" ] || [ -z "$STATIC_WEB_APP_NAME" ]; then
        print_error "Could not retrieve deployment outputs. Please check your resource group and deployment name."
        exit 1
    fi
    
    print_status "Found resources:"
    echo "  Function App: $FUNCTION_APP_NAME"
    echo "  Static Web App: $STATIC_WEB_APP_NAME"
    echo
    
    # Deploy components
    deploy_backend
    echo
    deploy_frontend
    echo
    configure_azure_ad
    echo
    validate_deployment
    echo
    
    print_success "🎉 Post-deployment automation completed!"
    echo
    print_status "Next steps:"
    echo "1. Complete Azure AD app registration (see warnings above)"
    echo "2. Test your application at: $STATIC_WEB_APP_URL"
    echo "3. Monitor your application via Application Insights"
    echo
    print_success "Your MONET Financial Management App is ready! 🎯"
}

# Run main function with all arguments
main "$@"