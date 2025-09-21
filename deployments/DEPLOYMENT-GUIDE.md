# MONET Azure Deployment Guide

## 🚀 One-Click Deployment Instructions

### Step 1: Deploy Infrastructure with Azure Deploy Button

1. Click the **Deploy to Azure** button in the main README
2. Sign in to Azure Portal
3. Fill in the deployment parameters:
   - **Project Name**: `monet` (or customize, 3-10 characters)
   - **Location**: Choose your preferred Azure region (e.g., "Central US")
   - **Environment**: Select `prod`, `dev`, or `staging`
   - **Static Web App Location**: Choose from available regions (limited options)
4. Click **"Review + create"** then **"Create"**
5. Wait for deployment to complete (5-10 minutes)
6. **Save the deployment outputs** - you'll need these for the next steps

### Step 2: Run Post-Deployment Automation

After the Azure infrastructure deployment completes:

```bash
# Navigate to the deployments directory
cd deployments

# Run the post-deployment script
./post-deploy.sh <resource-group-name> <deployment-name>

# Example:
./post-deploy.sh monet-rg-12345678 azuredeploy
```

The script will:
- Deploy your backend code to the Azure Function App
- Deploy your frontend code to the Azure Static Web App
- Provide Azure AD configuration instructions
- Validate the deployment

### Step 3: Configure Azure AD (Manual Step)

The Azure AD app registrations require manual configuration due to security requirements:

1. **Go to Azure Portal** > **Azure Active Directory** > **App registrations**
2. **Create two app registrations**:
   - `monet-dev-app` (for development)
   - `monet-prod-app` (for production)

3. **For each app registration**:
   - Set **Supported account types**: "Accounts in any organizational directory and personal Microsoft accounts"
   - **Add redirect URIs**:
     - Web: `https://your-static-web-app-url/auth/callback`
     - Web: `https://your-function-app-url/api/v1/auth/oauth/microsoft/callback`
     - Web: `http://localhost:5173/auth/callback` (for local development)

4. **Add API permissions**:
   - Microsoft Graph > Delegated > `User.Read`
   - Microsoft Graph > Delegated > `email`
   - Microsoft Graph > Delegated > `profile`

5. **Create client secrets** and add them to Key Vault:
   - Go to your Key Vault in Azure Portal
   - Add secrets:
     - `dev-azure-client-id`
     - `dev-azure-client-secret`
     - `prod-azure-client-id`
     - `prod-azure-client-secret`
     - `prod-azure-tenant-id`

6. **Grant admin consent** for the permissions

### Step 4: Verify Your Deployment

1. **Check your applications**:
   - Frontend: `https://monet-[suffix]-web.azurestaticapps.net`
   - Backend API: `https://monet-[suffix]-api.azurewebsites.net`

2. **Test the health endpoints**:
   ```bash
   curl https://your-function-app-url/api/health
   ```

3. **Monitor with Application Insights**:
   - Go to Azure Portal > Application Insights > your-app-insights-name
   - View logs, metrics, and performance data

## 🛠️ Troubleshooting

### Common Issues:

**1. Deployment fails with permission errors**
- Ensure you have Contributor access to the subscription
- Check that the resource group doesn't already exist with conflicting resources

**2. Function App deployment fails**
- Check that the Azure Functions Core Tools are installed
- Verify the resource names in the deployment outputs

**3. Static Web App deployment fails**
- Ensure GitHub repository is public or you have proper permissions
- Check that the build configuration is correct

**4. Azure AD authentication doesn't work**
- Verify redirect URIs match exactly (including https/http)
- Ensure client secrets are correctly stored in Key Vault
- Check that admin consent has been granted

### Manual Deployment Alternative:

If you prefer using Terraform directly:

```bash
cd deployments/terraform/azure
terraform init
terraform plan
terraform apply
```

## 📊 What Gets Deployed

### Azure Resources Created:
- **Resource Group**: Container for all resources
- **Azure Cosmos DB**: NoSQL database with dev/prod databases
  - Containers: users, accounts, transactions, plaid_tokens
- **Azure Functions**: Serverless Python 3.11 backend
- **Azure Static Web Apps**: React frontend hosting
- **Azure Key Vault**: Secure secrets management
- **Azure Storage Account**: Function App and file storage
- **Application Insights**: Monitoring and analytics

### Security Features:
- Managed Identity for secure authentication
- RBAC-enabled Key Vault access
- HTTPS-only enforcement
- CORS configuration
- Minimal required permissions

## 🎯 Next Steps

After successful deployment:

1. **Customize the application** with your branding and features
2. **Set up CI/CD pipelines** for continuous deployment
3. **Configure monitoring alerts** in Application Insights
4. **Set up backup policies** for Cosmos DB
5. **Review security settings** and apply any additional hardening

## 🆘 Need Help?

- Check the deployment logs in Azure Portal
- Review the post-deployment script output
- Ensure all prerequisites are met
- Contact support if issues persist

---

**🎉 Congratulations! Your MONET Financial Management App is now running on Azure!**