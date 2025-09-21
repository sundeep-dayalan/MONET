#!/bin/bash

# MONET Azure Deployment Script with Free Tier Fallback
# This script attempts to deploy with Cosmos DB free tier first,
# then falls back to standard tier if free tier is unavailable

set -e

# Configuration
RESOURCE_GROUP="MonetAppRG"
TEMPLATE_FILE="azuredeploy.json"
PARAMETERS_FILE="azuredeploy.parameters.free-tier.json"
FALLBACK_PARAMETERS_FILE="azuredeploy.parameters.json"
DEPLOYMENT_NAME="monet-deployment-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting MONET Azure Deployment${NC}"
echo "Resource Group: $RESOURCE_GROUP"
echo "Template: $TEMPLATE_FILE"
echo ""

# Check if resource group exists, create if not
echo -e "${YELLOW}📋 Checking resource group...${NC}"
if ! az group show --name $RESOURCE_GROUP >/dev/null 2>&1; then
    echo "Creating resource group: $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location "Central US"
else
    echo "Resource group already exists: $RESOURCE_GROUP"
fi

# Attempt deployment with free tier first
echo -e "${YELLOW}💰 Attempting deployment with Cosmos DB free tier...${NC}"
if az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --template-file $TEMPLATE_FILE \
    --parameters @$PARAMETERS_FILE \
    --name "$DEPLOYMENT_NAME-free-tier" \
    --no-wait false 2>/dev/null; then
    
    echo -e "${GREEN}✅ Deployment successful with free tier!${NC}"
    
else
    echo -e "${RED}❌ Free tier deployment failed. Attempting fallback to standard tier...${NC}"
    
    # Fallback to standard tier
    echo -e "${YELLOW}🔄 Deploying with standard Cosmos DB tier...${NC}"
    if az deployment group create \
        --resource-group $RESOURCE_GROUP \
        --template-file $TEMPLATE_FILE \
        --parameters @$FALLBACK_PARAMETERS_FILE \
        --name "$DEPLOYMENT_NAME-standard-tier" \
        --no-wait false; then
        
        echo -e "${GREEN}✅ Deployment successful with standard tier!${NC}"
        
    else
        echo -e "${RED}❌ Deployment failed with both free and standard tiers.${NC}"
        echo "Please check the Azure portal for detailed error information."
        exit 1
    fi
fi

echo ""
echo -e "${GREEN}🎉 MONET deployment completed successfully!${NC}"
echo ""
echo "Next steps:"
echo "1. Check the Azure portal for deployed resources"
echo "2. Configure your application settings"
echo "3. Deploy your application code using the post-deploy script"
echo ""
echo "Run './post-deploy.sh' to deploy your application code to the infrastructure."