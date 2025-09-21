# Sage Financial Management App

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fsundeep-dayalan%2FMONET%2Fazure%2Fdeployments%2Fazuredeploy.json)

This project provides a comprehensive solution for financial management, built with a modern stack.

## One-Click Deployment to Azure

This repository is configured for a streamlined, one-click deployment to Azure using Terraform and a "Deploy to Azure" button.

### What this deployment does:

*   **Provisions Infrastructure with Terraform:** All necessary Azure resources are defined as code using Terraform, ensuring a repeatable and reliable setup. This includes:
    *   Resource Group
    *   Storage Account
    *   Cosmos DB (with databases and containers)
    *   Application Insights
    *   Key Vault
    *   Function App (for the backend)
    *   Static Web App (for the frontend)
*   **Deploys Application Code:**
    *   The Node.js backend is deployed to the Azure Function App.
    *   The React frontend is built and deployed to the Azure Static Web App.

### How to Deploy:

1.  Click the **Deploy to Azure** button above.
2.  You will be redirected to the Azure Portal.
3.  Fill in the required parameters (project name, location, etc.).
4.  Click **Review + create** and then **Create**.

The deployment process will take several minutes. Once complete, the outputs will provide you with the URLs for your frontend and backend services.
