# MONET Azure Deployment Guide

This guide provides multiple deployment options for the MONET financial management application on Azure.

## 🚀 Quick Deployment Options

### Option 1: One-Click Deploy to Azure (Recommended for First-Time Users)

Click the button below to deploy with Cosmos DB free tier (if available in your subscription):

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsundeep-dayalan%2FMONET%2Fazure%2Fdeployments%2Fazuredeploy.json)

**Note**: If you already have a Cosmos DB free tier account in your subscription, this deployment will fail. Use Option 2 or 3 below.

### Option 2: Deploy Without Free Tier

If you already have a Cosmos DB free tier account or prefer standard pricing:

[![Deploy to Azure (Standard Tier)](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsundeep-dayalan%2FMONET%2Fazure%2Fdeployments%2Fazuredeploy.json/createUIDefinitionUri/https%3A%2F%2Fraw.githubusercontent.com%2Fsundeep-dayalan%2FMONET%2Fazure%2Fdeployments%2Fazuredeploy.parameters.no-free-tier.json)

### Option 3: Intelligent Deployment with Automatic Fallback (Recommended for CLI Users)

Use our smart deployment script that tries free tier first and automatically falls back to standard tier:

```bash
cd deployments
./deploy-with-fallback.sh
```

This script will:
1. ✅ Try to deploy with Cosmos DB free tier
2. 🔄 Automatically fallback to standard tier if free tier is unavailable
3. 📊 Provide clear status messages throughout the process

## 🏗️ Infrastructure Components

The deployment creates the following Azure resources:

| Resource | Purpose | Pricing Tier |
|----------|---------|--------------|
| **Cosmos DB** | Document database for application data | Serverless (Free tier preferred, Standard fallback) |
| **Static Web App** | Frontend hosting for React application | Free tier |
| **Key Vault** | Secure storage for secrets and keys | Standard |
| **Storage Account** | File storage and backend data | Standard LRS |
| **Application Insights** | Application monitoring and analytics | Free tier |

## 💰 Cost Considerations

### With Free Tier (Recommended)
- **Cosmos DB**: Free (400 RU/s, 5GB storage)
- **Static Web App**: Free (100GB bandwidth/month)
- **Application Insights**: Free (1GB/month)
- **Key Vault**: ~$0.03/month (10,000 operations)
- **Storage Account**: ~$0.05/month (minimal usage)

**Total**: ~$0.08/month

### Standard Tier Fallback
- **Cosmos DB**: Pay-per-use serverless (~$0.25/million RUs)
- Other resources remain the same
- **Estimated**: $1-5/month for typical usage

## 🔧 Manual Deployment (Advanced)

For advanced users who want full control:

### Prerequisites
- Azure CLI installed and logged in
- Azure subscription with appropriate permissions

### Step 1: Create Resource Group
```bash
az group create --name MonetAppRG --location "Central US"
```

### Step 2: Deploy Infrastructure (Free Tier)
```bash
az deployment group create \
  --resource-group MonetAppRG \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.json
```

### Step 3: Deploy Infrastructure (Standard Tier)
If free tier fails:
```bash
az deployment group create \
  --resource-group MonetAppRG \
  --template-file azuredeploy.json \
  --parameters @azuredeploy.parameters.no-free-tier.json
```

### Step 4: Deploy Application Code
```bash
./post-deploy.sh
```

## ⚠️ Common Issues and Solutions

### "Free tier has already been applied to another Azure Cosmos DB account"
**Solution**: Use Option 2 or 3 above, or delete your existing free tier Cosmos DB account.

### "VM quota exceeded"
**Solution**: The template automatically uses quota-friendly resources. If issues persist, try a different Azure region.

### "Key Vault name already exists"
**Solution**: Change the `projectName` parameter to create unique resource names.

## 📋 Post-Deployment Steps

1. **Verify Resources**: Check the Azure portal to ensure all resources are created
2. **Configure Secrets**: Add your API keys and secrets to Key Vault
3. **Deploy Code**: Run the post-deployment script to deploy your application
4. **Test Application**: Verify the frontend and backend are working correctly

## 🛠️ Troubleshooting

### View Deployment Logs
```bash
az deployment group show --resource-group MonetAppRG --name <deployment-name>
```

### Check Resource Status
```bash
az resource list --resource-group MonetAppRG --output table
```

### Clean Up Resources
```bash
az group delete --name MonetAppRG --yes --no-wait
```

## 📞 Support

If you encounter issues:
1. Check the [Common Issues](#-common-issues-and-solutions) section above
2. Review Azure deployment logs in the portal
3. Open an issue in the GitHub repository with error details

---

**Next**: After successful deployment, see [DEVELOPMENT.md](DEVELOPMENT.md) for local development setup.