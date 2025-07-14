// Main Bicep template for Cost Dashboard infrastructure
targetScope = 'subscription'

@description('Environment name (dev, staging, prod)')
param environment string = 'dev'

@description('Location for resources')
param location string = 'East US'

@description('Budget amount in USD')
param budgetAmount int = 1000

@description('Email addresses for cost alerts')
param alertEmails array = []

@description('Tags to apply to resources')
param tags object = {
  Environment: environment
  Project: 'CostDashboard'
  ManagedBy: 'Bicep'
}

// Create resource group for cost management resources
resource costManagementRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-cost-dashboard-${environment}'
  location: location
  tags: tags
}

// Deploy cost management resources
module costManagement 'modules/cost-management.bicep' = {
  name: 'cost-management-deployment'
  scope: costManagementRG
  params: {
    environment: environment
    budgetAmount: budgetAmount
    alertEmails: alertEmails
    tags: tags
  }
}

// Deploy monitoring and dashboards
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring-deployment'
  scope: costManagementRG
  params: {
    environment: environment
    location: location
    tags: tags
  }
}

// Deploy storage for cost data
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  scope: costManagementRG
  params: {
    environment: environment
    location: location
    tags: tags
  }
}

// Deploy Function App for cost data processing
module functionApp 'modules/function-app.bicep' = {
  name: 'function-app-deployment'
  scope: costManagementRG
  params: {
    environment: environment
    location: location
    tags: tags
    storageAccountName: storage.outputs.storageAccountName
  }
}

// Outputs
output resourceGroupName string = costManagementRG.name
output storageAccountName string = storage.outputs.storageAccountName
output functionAppName string = functionApp.outputs.functionAppName
output dashboardUrl string = monitoring.outputs.dashboardUrl
