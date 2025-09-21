#!/bin/bash

set -e
set -x # Enable debugging

# --- Pre-flight checks and dependency installation ---
echo "Starting deployment script..."

# Check for Azure CLI
if ! command -v az &> /dev/null; then
    echo "Azure CLI (az) could not be found. Please ensure it's installed in the execution environment."
    exit 1
fi
echo "Azure CLI found."

# Install Azure Functions Core Tools and SWA CLI
echo "Installing Azure Functions Core Tools and SWA CLI via npm..."
npm install -g azure-functions-core-tools@4 --unsafe-perm true
npm install -g @azure/static-web-apps-cli
echo "Dependencies installed."

# --- Terraform Infrastructure Deployment ---
echo "Navigating to Terraform directory..."
# Navigate to the Terraform directory relative to the script location
cd "$(dirname "$0")/terraform/azure"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply Terraform configuration
echo "Applying Terraform infrastructure..."
terraform apply -auto-approve
echo "Terraform apply completed."

# --- Application Deployment ---

# Capture Terraform outputs
echo "Capturing Terraform outputs..."
FUNCTION_APP_URL=$(terraform output -raw function_app_url)
STATIC_WEB_APP_URL=$(terraform output -raw static_web_app_url)
RESOURCE_GROUP_NAME=$(terraform output -raw resource_group_name)

# Derive resource names from URLs
FUNCTION_APP_NAME=$(echo "$FUNCTION_APP_URL" | awk -F'//|.' '{print $2}')
STATIC_WEB_APP_NAME=$(echo "$STATIC_WEB_APP_URL" | awk -F'//|.' '{print $2}')
echo "Function App Name: $FUNCTION_APP_NAME"
echo "Static Web App Name: $STATIC_WEB_APP_NAME"
echo "Resource Group Name: $RESOURCE_GROUP_NAME"

# Deploy backend
echo "Navigating to backend directory..."
cd ../../../packages/core
echo "Deploying backend to Function App: $FUNCTION_APP_NAME..."
func azure functionapp publish "$FUNCTION_APP_NAME" --force
echo "Backend deployment finished."

# Deploy frontend
echo "Navigating to frontend directory..."
cd ../client
echo "Installing frontend dependencies..."
npm install
echo "Building frontend application..."
npm run build
echo "Frontend build completed."

echo "Retrieving Static Web App deployment token..."
SWA_DEPLOYMENT_TOKEN=$(az staticwebapp secrets list --name "$STATIC_WEB_APP_NAME" --resource-group "$RESOURCE_GROUP_NAME" --query "properties.apiKey" -o tsv)

if [ -z "$SWA_DEPLOYMENT_TOKEN" ]; then
    echo "Error: Could not retrieve Static Web App deployment token."
    exit 1
fi
echo "Deployment token retrieved."

echo "Deploying frontend to Static Web App: $STATIC_WEB_APP_NAME..."
swa deploy ./dist --deployment-token "$SWA_DEPLOYMENT_TOKEN"
echo "Frontend deployment finished."


# --- Final Summary ---
echo "----------------------------------------"
echo "Deployment Summary"
echo "----------------------------------------"
echo "Function App URL: https://$FUNCTION_APP_URL"
echo "Static Web App URL: https://$STATIC_WEB_APP_URL"
echo "----------------------------------------"
echo "Deployment script completed successfully!"
