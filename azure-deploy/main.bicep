@description('The base name for all resources. A unique string will be appended to this.')
param appName string = 'fn-node-ts-gh'

@description('The location for all resources.')
param location string = resourceGroup().location

@description('The URL of the GitHub repository to deploy.')
param repoURL string = 'https://github.com/sundeep-dayalan/MONET.git'

@description('The branch of the repository to deploy.')
param branch string = 'dummy'

// Generate unique names for resources that require it
var uniqueSuffix = uniqueString(resourceGroup().id)
var functionAppName = '${appName}-${uniqueSuffix}'
var storageAccountName = 'st${replace(uniqueSuffix, '-', '')}' // Storage names must be alphanumeric and lowercase
var hostingPlanName = '${appName}-plan-${uniqueSuffix}'

// Create a storage account required by the function app
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

// Create a consumption plan to host the function app
resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1' // Y1 is the SKU for the Consumption plan
    tier: 'Dynamic'
  }
}

// Create the function app
resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https,AccountName=${storageAccountName},AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '0' // We are using source control deploy, not a package URL
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
      ]
      ftpsState: 'FtpsOnly'
    }
    httpsOnly: true
  }
}

// Configure the function app to deploy from the specified GitHub repository
resource sourceControl 'Microsoft.Web/sites/sourcecontrols@2022-09-01' = {
  name: 'web'
  parent: functionApp
  properties: {
    repoUrl: repoURL
    branch: branch
    isManualIntegration: true // This lets Kudu handle the build/deploy
  }
}

// Output the hostname of the deployed function app
output functionAppHostname string = functionApp.properties.defaultHostName
