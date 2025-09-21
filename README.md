# Monet Financial Management App

## 🚀 Deploy to Azure

### Quick Deploy (Standard Tier - Always Works)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsundeep-dayalan%2FMONET%2Fazure%2Fdeployments%2Fazuredeploy.json)

**Cost**: ~$1-5/month | **Deployment**: Always succeeds | **Setup Time**: 5-10 minutes

### Free Tier Deploy (If Available)
Want to try the free tier first? Use our intelligent deployment script:
```bash
git clone https://github.com/sundeep-dayalan/MONET.git
cd MONET/deployments
./deploy-with-fallback.sh
```
**Cost**: ~$0.08/month (if free tier available) | **Fallback**: Automatic to standard tier

---

This project provides a comprehensive solution for financial management, built with a modern stack.

## 🚀 One-Click Deployment to Azure

Deploy the complete MONET Financial Management App infrastructure to Azure with a single click! This deployment automatically provisions all necessary Azure resources and prepares your application for immediate use.

### 🏗️ What gets deployed:

**Core Infrastructure:**
*   **Resource Group** - Logical container for all resources
*   **Azure Cosmos DB** - NoSQL database with dev/prod databases and containers (users, accounts, transactions, plaid_tokens)
*   **Azure Functions** - Serverless backend API (Python 3.11)
*   **Azure Static Web Apps** - React frontend hosting
*   **Azure Key Vault** - Secure secrets management
*   **Azure Storage Account** - File storage and Function App storage
*   **Application Insights** - Monitoring and analytics

**Security & Configuration:**
*   Managed Identity for secure authentication
*   RBAC-enabled Key Vault access
*   CORS configuration for cross-origin requests
*   HTTPS-only enforcement
*   Minimal required permissions

### 📋 Prerequisites:

- Azure subscription
- Contributor access to create resources
- GitHub account (for code deployment)

### 🎯 How to Deploy:

1.  **Click the Deploy to Azure button above** ⬆️
2.  **Sign in to Azure Portal** (if not already signed in)
3.  **Configure deployment parameters:**
    - Project Name: `monet` (or customize)
    - Location: Choose your preferred Azure region
    - Environment: `prod`, `dev`, or `staging`
    - Static Web App Location: Choose from available regions
4.  **Click "Review + create"** then **"Create"**
5.  **Wait for deployment** (typically 5-10 minutes)

### 🎉 Post-Deployment Steps:

After the infrastructure deployment completes:

1. **Note the output URLs** from the deployment results
2. **Configure Azure AD applications** (see post-deployment guide)
3. **Deploy application code** to Function App and Static Web App
4. **Access your MONET app** via the provided Static Web App URL

### 📊 What you'll get:

- **Frontend URL**: `https://monet-[suffix]-web.azurestaticapps.net`
- **Backend API URL**: `https://monet-[suffix]-api.azurewebsites.net`
- **Cosmos DB**: Ready with dev/prod databases
- **Key Vault**: Configured for secure secrets management
- **Monitoring**: Application Insights ready for observability

### 🔧 Manual Deployment Alternative:

If you prefer to deploy manually using Terraform:
