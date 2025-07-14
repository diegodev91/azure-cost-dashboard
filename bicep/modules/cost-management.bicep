// Cost Management module
@description('Environment name')
param environment string

@description('Budget amount in USD')
param budgetAmount int

@description('Email addresses for cost alerts')
param alertEmails array

@description('Tags to apply to resources')
param tags object

// Budget for subscription-level cost tracking
resource budget 'Microsoft.Consumption/budgets@2021-10-01' = {
  name: 'budget-${environment}'
  properties: {
    timePeriod: {
      startDate: '2024-01-01'
      endDate: '2025-12-31'
    }
    timeGrain: 'Monthly'
    amount: budgetAmount
    category: 'Cost'
    notifications: {
      Actual_GreaterThan_80_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: alertEmails
        contactRoles: [
          'Owner'
          'Contributor'
        ]
      }
      Forecasted_GreaterThan_100_Percent: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: alertEmails
        contactRoles: [
          'Owner'
          'Contributor'
        ]
      }
    }
  }
}

// Action Group for cost alerts
resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: 'ag-cost-alerts-${environment}'
  location: 'Global'
  tags: tags
  properties: {
    groupShortName: 'CostAlerts'
    enabled: true
    emailReceivers: [for email in alertEmails: {
      name: replace(email, '@', '-at-')
      emailAddress: email
      useCommonAlertSchema: true
    }]
  }
}

output budgetId string = budget.id
output actionGroupId string = actionGroup.id
