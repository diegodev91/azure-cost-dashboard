using './main.bicep'

param environment = 'dev'
param location = 'East US'
param budgetAmount = 1000
param alertEmails = [
  'admin@yourcompany.com'
  'finance@yourcompany.com'
]
