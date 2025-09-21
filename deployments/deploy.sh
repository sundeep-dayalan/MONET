#!/bin/bash

# MONET - Complete Azure Deployment with Terraform
# Follows the same pattern as the Sage shell script but for MONET project
# Provisions infrastructure with Terraform and deploys applications

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="monet"
LOCATION="Central US"
ENVIRONMENT="prod"

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to retry commands
retry_command() {
    local max_attempts=${1:-3}
    local delay=${2:-5}
    local operation_name=${3:-"Operation"}
    shift 3
    local cmd=("$@")
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        print_status "Attempting $operation_name (attempt $attempt/$max_attempts)..."
        
        if "${cmd[@]}"; then
            if [ $attempt -gt 1 ]; then
                print_success "$operation_name succeeded on attempt $attempt"
            fi
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                local wait_time=$((delay * attempt))
                print_warning "$operation_name failed (attempt $attempt/$max_attempts). Retrying in ${wait_time}s..."
                sleep $wait_time
            else
                print_error "$operation_name failed after $max_attempts attempts"
                return 1
            fi
        fi
        ((attempt++))
    done
}

# Step 1: Prerequisites check
setup_prerequisites() {
    print_header "STEP 1: PREREQUISITES CHECK"
    
    # Check Terraform
    if ! command_exists terraform; then
        print_error "Terraform is not installed. Install from: https://www.terraform.io/downloads"
        exit 1
    fi
    
    # Check Azure CLI
    if ! command_exists az; then
        print_error "Azure CLI is not installed. Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if logged into Azure
    if ! az account show &>/dev/null; then
        print_error "Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check Node.js
    if ! command_exists node; then
        print_error "Node.js is not installed. Install from: https://nodejs.org/"
        exit 1
    fi
    
    print_success "All prerequisites met!"
}

# Step 2: Initialize Terraform
init_terraform() {
    print_header "STEP 2: TERRAFORM INITIALIZATION"
    
    cd deployments/terraform/azure
    
    print_status "Initializing Terraform..."
    retry_command 3 5 "Terraform init" terraform init
    
    print_status "Validating Terraform configuration..."
    terraform validate
    
    print_success "Terraform initialized and validated!"
    cd ../../..
}

# Step 3: Plan and Apply Terraform
deploy_infrastructure() {
    print_header "STEP 3: INFRASTRUCTURE DEPLOYMENT"
    
    cd deployments/terraform/azure
    
    print_status "Creating Terraform execution plan..."
    terraform plan -out=tfplan
    
    print_warning "Review the plan above. Do you want to proceed with infrastructure deployment?"
    read -p "Continue? (y/n): " continue_deploy
    
    if [[ ! "$continue_deploy" =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled by user"
        cd ../../..
        exit 0
    fi
    
    print_status "Deploying infrastructure with Terraform..."
    retry_command 2 10 "Terraform apply" terraform apply tfplan
    
    print_success "Infrastructure deployed successfully!"
    
    # Get outputs
    RESOURCE_GROUP_NAME=$(terraform output -raw resource_group_name)
    FUNCTION_APP_URL=$(terraform output -raw function_app_url)
    STATIC_WEB_APP_URL=$(terraform output -raw static_web_app_url)
    
    print_status "Infrastructure outputs:"
    print_status "  Resource Group: $RESOURCE_GROUP_NAME"
    print_status "  Function App URL: https://$FUNCTION_APP_URL"
    print_status "  Static Web App URL: https://$STATIC_WEB_APP_URL"
    
    cd ../../..
}

# Step 4: Deploy Backend
deploy_backend() {
    print_header "STEP 4: BACKEND DEPLOYMENT"
    
    # Extract function app name from URL
    local function_app_name=$(echo "$FUNCTION_APP_URL" | cut -d. -f1 | sed 's/https\?:\/\///')
    
    print_status "Deploying backend to Function App: $function_app_name"
    
    chmod +x deployments/deploy-backend.sh
    ./deployments/deploy-backend.sh "$function_app_name" "$RESOURCE_GROUP_NAME"
    
    print_success "Backend deployment completed!"
}

# Step 5: Deploy Frontend
deploy_frontend() {
    print_header "STEP 5: FRONTEND DEPLOYMENT"
    
    # Extract static web app name from resource group or terraform output
    local static_web_app_name=$(az staticwebapp list --resource-group "$RESOURCE_GROUP_NAME" --query "[0].name" -o tsv)
    
    if [ -z "$static_web_app_name" ]; then
        print_error "Could not find Static Web App in resource group: $RESOURCE_GROUP_NAME"
        return 1
    fi
    
    print_status "Deploying frontend to Static Web App: $static_web_app_name"
    
    chmod +x deployments/deploy-frontend.sh
    ./deployments/deploy-frontend.sh "$static_web_app_name" "https://$FUNCTION_APP_URL" "$RESOURCE_GROUP_NAME"
    
    print_success "Frontend deployment completed!"
}

# Step 6: Final configuration and restart
finalize_deployment() {
    print_header "STEP 6: FINALIZATION"
    
    local function_app_name=$(echo "$FUNCTION_APP_URL" | cut -d. -f1 | sed 's/https\?:\/\///')
    
    print_status "Restarting Function App to ensure all settings are loaded..."
    az functionapp restart --name "$function_app_name" --resource-group "$RESOURCE_GROUP_NAME" --output none
    
    print_status "Waiting for services to be ready..."
    sleep 30
    
    print_success "Deployment finalized!"
}

# Final summary
display_summary() {
    print_header "🎉 MONET DEPLOYMENT COMPLETED SUCCESSFULLY!"
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "                        DEPLOYMENT SUMMARY"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    print_success "All Azure resources have been created and configured!"
    echo ""
    echo "📦 RESOURCE GROUP: $RESOURCE_GROUP_NAME"
    echo "📍 LOCATION: $LOCATION"
    echo ""
    echo "🔗 APPLICATION URLS:"
    echo "   Frontend:  https://$STATIC_WEB_APP_URL"
    echo "   Backend:   https://$FUNCTION_APP_URL"
    echo "   Health:    https://$FUNCTION_APP_URL/api/health"
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    echo "                           NEXT STEPS"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "1️⃣  TEST YOUR APPLICATION:"
    echo "   • Frontend: Visit https://$STATIC_WEB_APP_URL"
    echo "   • Backend health: curl https://$FUNCTION_APP_URL/api/health"
    echo ""
    echo "2️⃣  MICROSOFT ENTRA ID LOGIN:"
    echo "   • Azure AD is configured for both personal and organizational accounts"
    echo "   • Login at: https://$STATIC_WEB_APP_URL"
    echo ""
    echo "3️⃣  MONITOR & MANAGE:"
    echo "   • Azure portal: https://portal.azure.com"
    echo "   • Application Insights: Monitor performance and errors"
    echo "   • Key Vault: Manage secrets securely"
    echo ""
    print_warning "⏱️  Services may take 2-3 minutes to be fully available"
    
    print_success "🎉 Your MONET Financial Management App is ready!"
    echo ""
}

# Error handling
handle_error() {
    local exit_code=$?
    print_error "Deployment failed at step: $CURRENT_STEP"
    print_error "Exit code: $exit_code"
    echo ""
    echo "🔧 TROUBLESHOOTING:"
    echo "• Check Azure portal for resource status"
    echo "• Verify Terraform state: cd deployments/terraform/azure && terraform show"
    echo "• Check Azure service health: https://status.azure.com"
    exit $exit_code
}

# Main execution
main() {
    clear
    echo "════════════════════════════════════════════════════════════════"
    echo "        🏦 MONET - Azure Deployment with Terraform v1.0"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    
    trap handle_error ERR
    
    CURRENT_STEP="Prerequisites"; setup_prerequisites
    CURRENT_STEP="Terraform Init"; init_terraform
    CURRENT_STEP="Infrastructure"; deploy_infrastructure
    CURRENT_STEP="Backend"; deploy_backend
    CURRENT_STEP="Frontend"; deploy_frontend
    CURRENT_STEP="Finalization"; finalize_deployment
    
    display_summary
}

# Help function
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "MONET Financial Management App - Azure Deployment with Terraform"
    echo ""
    echo "Usage: ./deploy.sh"
    echo ""
    echo "This script automatically:"
    echo "• Validates prerequisites (Terraform, Azure CLI, Node.js)"
    echo "• Deploys infrastructure using Terraform"
    echo "• Deploys backend to Azure Function App"
    echo "• Deploys frontend to Azure Static Web App"
    echo "• Configures all integrations and security"
    echo ""
    echo "Prerequisites:"
    echo "• Azure CLI installed and logged in (az login)"
    echo "• Terraform installed"
    echo "• Node.js 18+ installed"
    echo "• Active Azure subscription with appropriate permissions"
    echo ""
    echo "Project structure expected:"
    echo "• packages/core/ - Backend (Node.js/TypeScript)"
    echo "• packages/client/ - Frontend (React)"
    echo "• deployments/terraform/azure/ - Terraform configuration"
    echo ""
    exit 0
fi

# Run main function
main "$@"
