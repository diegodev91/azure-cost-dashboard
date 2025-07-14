// Monitoring and Dashboard module
@description('Environment name')
param environment string

@description('Location for resources')
param location string

@description('Tags to apply to resources')
param tags object

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: 'law-cost-${environment}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
  }
}

// Azure Monitor Workbook for Cost Analysis
resource costWorkbook 'Microsoft.Insights/workbooks@2022-04-01' = {
  name: guid('cost-workbook-${environment}')
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: 'Cost Analysis Dashboard - ${environment}'
    serializedData: string({
      version: 'Notebook/1.0'
      items: [
        {
          type: 1
          content: {
            json: '# Azure Cost Analysis Dashboard\n\nThis dashboard provides insights into your Azure spending across resource groups.'
          }
        }
        {
          type: 3
          content: {
            version: 'KqlItem/1.0'
            query: 'Usage\n| where TimeGenerated > ago(30d)\n| summarize TotalCost = sum(Quantity * UnitPrice) by Resource\n| top 10 by TotalCost desc'
            size: 0
            title: 'Top 10 Resources by Cost (Last 30 Days)'
            timeContext: {
              durationMs: 2592000000
            }
            queryType: 0
            resourceType: 'microsoft.operationalinsights/workspaces'
          }
        }
      ]
    })
    category: 'workbook'
    sourceId: logAnalyticsWorkspace.id
  }
}

// Dashboard for cost visualization
resource dashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: 'dashboard-cost-${environment}'
  location: location
  tags: tags
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: {
              x: 0
              y: 0
              rowSpan: 4
              colSpan: 6
            }
            metadata: {
              inputs: []
              type: 'Extension/HubsExtension/PartType/MarkdownPart'
              settings: {
                content: {
                  settings: {
                    content: '# Azure Cost Dashboard - ${environment}\n\n## Overview\nThis dashboard provides comprehensive cost monitoring and analysis for the **${environment}** environment.\n\n### Key Features\n- Real-time cost tracking\n- Budget monitoring and alerts\n- Resource group cost breakdown\n- Service-level cost analysis\n- Trend analysis and forecasting\n\n### Quick Links\n- [Cost Management + Billing](https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview)\n- [Budget Management](https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/budgets)\n- [Cost Analysis](https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/costanalysis)'
                    title: 'Cost Dashboard - ${environment}'
                  }
                }
              }
            }
          }
          {
            position: {
              x: 6
              y: 0
              rowSpan: 2
              colSpan: 3
            }
            metadata: {
              inputs: []
              type: 'Extension/HubsExtension/PartType/MarkdownPart'
              settings: {
                content: {
                  settings: {
                    content: '## 📊 Quick Stats\n\n- **Environment**: ${environment}\n- **Budget Alerts**: Enabled\n- **Monitoring**: Active\n- **Deployment**: Automated'
                    title: 'Environment Status'
                  }
                }
              }
            }
          }
          {
            position: {
              x: 9
              y: 0
              rowSpan: 2
              colSpan: 3
            }
            metadata: {
              inputs: []
              type: 'Extension/HubsExtension/PartType/MarkdownPart'
              settings: {
                content: {
                  settings: {
                    content: '## 🚨 Alert Thresholds\n\n- **Warning**: 80% of budget\n- **Critical**: 100% of budget\n- **Notifications**: Email alerts enabled\n- **Frequency**: Real-time monitoring'
                    title: 'Alert Configuration'
                  }
                }
              }
            }
          }
          {
            position: {
              x: 6
              y: 2
              rowSpan: 2
              colSpan: 6
            }
            metadata: {
              inputs: []
              type: 'Extension/HubsExtension/PartType/MarkdownPart'
              settings: {
                content: {
                  settings: {
                    content: '## 📈 Getting Started\n\n1. **View Costs**: Navigate to Cost Management + Billing\n2. **Analyze Trends**: Use Cost Analysis for detailed breakdowns\n3. **Monitor Budgets**: Check budget utilization and forecasts\n4. **Set Alerts**: Configure additional cost alerts as needed\n5. **Optimize**: Use recommendations to reduce costs\n\n**Need Help?** Check the [Cost Management documentation](https://docs.microsoft.com/azure/cost-management-billing/)'
                    title: 'Next Steps'
                  }
                }
              }
            }
          }
        ]
      }
    ]
    metadata: {
      model: {
        timeRange: {
          value: {
            relative: {
              duration: 24
              timeUnit: 1
            }
          }
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
        }
      }
    }
  }
}

output workspaceId string = logAnalyticsWorkspace.id
output workbookId string = costWorkbook.id
output dashboardUrl string = 'https://portal.azure.com/#@${tenant().tenantId}/dashboard/arm${dashboard.id}'
