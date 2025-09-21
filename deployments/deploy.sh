#!/bin/bash

set -e

# Navigate to the Terraform directory
cd "$(dirname "$0")/terraform/azure"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Apply Terraform configuration
echo "Applying Terraform infrastructure..."
terraform apply -auto-approve

# Capture outputs
echo "Capturing Terraform outputs..."
FUNCTION_APP_URL=$(terraform output -raw function_app_url)
STATIC_WEB_APP_URL=$(terraform output -raw static_web_app_url)
FUNCTION_APP_NAME=$(echo "$FUNCTION_APP_URL" | awk -F'//|.' '{print $2}')

# Navigate to the backend directory (assuming it's at ../../../packages/core)
cd ../../../packages/core

# Deploy backend
echo "Deploying backend..."
# Assuming func cli is installed and configured
func azure functionapp publish "$FUNCTION_APP_NAME"

# Navigate to the frontend directory (assuming it's at ../../client)
cd ../client

# Build and deploy frontend
echo "Building and deploying frontend..."
npm install
npm run build

# Assuming swa cli is installed and configured
# The static web app name can be derived from the URL as well
STATIC_WEB_APP_NAME=$(echo "$STATIC_WEB_APP_URL" | awk -F'//|.' '{print $2}')
SWA_DEPLOYMENT_TOKEN=$(az staticwebapp secrets list --name "$STATIC_WEB_APP_NAME" --query "properties.apiKey" -o tsv)

swa deploy ./dist --deployment-token "$SWA_DEPLOYMENT_TOKEN"

# Final Summary
echo "----------------------------------------"
echo "Deployment Summary"
echo "----------------------------------------"
echo "Function App URL: https://$FUNCTION_APP_URL"
echo "Static Web App URL: https://$STATIC_WEB_APP_URL"
echo "----------------------------------------"
