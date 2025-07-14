# Azure Cost Dashboard - Setup Guide

## Prerequisites

Before setting up the Azure Cost Dashboard, ensure you have:

### Azure Requirements
- Azure subscription with appropriate permissions
- Resource groups you want to monitor
- Azure CLI installed locally (for manual deployment)

### GitHub Requirements
- GitHub repository
- GitHub Actions enabled
- Repository secrets configured

### Required Permissions
Your Azure service principal needs these permissions:
- **Cost Management Reader** (at subscription level)
- **Contributor** (for resource deployment)
- **Reader** (for resource group access)

## Setup Instructions

### 1. Fork/Clone Repository

```bash
git clone <your-repository-url>
cd cost-dashboard
```

### 2. Configure Azure Service Principal

Create a service principal for GitHub Actions:

```bash
# Login to Azure
az login

# Create service principal
az ad sp create-for-rbac \
  --name "cost-dashboard-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/<YOUR_SUBSCRIPTION_ID>" \
  --sdk-auth

# Assign Cost Management Reader role
az role assignment create \
  --assignee <SERVICE_PRINCIPAL_ID> \
  --role "Cost Management Reader" \
  --scope "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
```

### 3. Configure GitHub Secrets

Add these secrets to your GitHub repository:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | Service Principal Client ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_TENANT_ID` | Azure Tenant ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | `11111111-2222-3333-4444-555555555555` |

#### Optional Email Configuration
If you want email reports, add these secrets:

| Secret Name | Description |
|-------------|-------------|
| `SMTP_SERVER` | SMTP server hostname |
| `SMTP_PORT` | SMTP port (usually 587) |
| `SMTP_USERNAME` | SMTP username |
| `SMTP_PASSWORD` | SMTP password |

### 4. Configure GitHub Variables

Add these variables to your repository:

| Variable Name | Description | Example |
|---------------|-------------|---------|
| `AZURE_LOCATION` | Azure region | `East US` |
| `BUDGET_AMOUNT` | Monthly budget limit | `1000` |
| `ALERT_EMAILS` | Email addresses for alerts | `["admin@company.com"]` |
| `RESOURCE_GROUPS_TO_MONITOR` | Resource groups to track | `["rg-project1", "rg-project2"]` |
| `SMTP_ENABLED` | Enable email reports | `true` |
| `REPORT_RECIPIENTS` | Email report recipients | `admin@company.com,finance@company.com` |

### 5. Update Configuration Files

#### Edit `config/config.json`
```json
{
  "environments": {
    "dev": {
      "subscriptionId": "YOUR_DEV_SUBSCRIPTION_ID",
      "location": "East US",
      "budgetAmount": 500,
      "alertEmails": ["admin@yourcompany.com"],
      "resourceGroupsToMonitor": [
        "rg-project1-dev",
        "rg-project2-dev"
      ]
    }
  }
}
```

#### Create Bicep Parameters File
Copy and customize the parameters file:

```bash
cp bicep/bicep.parameters.example.bicepparam bicep/bicep.parameters.bicepparam
```

Edit with your values:
```
using './main.bicep'

param environment = 'dev'
param location = 'East US'
param budgetAmount = 1000
param alertEmails = [
  'your-email@company.com'
]
param resourceGroupsToMonitor = [
  'rg-your-project-dev'
]
```

### 6. Deploy Infrastructure

#### Automatic Deployment (Recommended)
Push changes to the main branch to trigger automatic deployment:

```bash
git add .
git commit -m "Initial cost dashboard setup"
git push origin main
```

#### Manual Deployment
Deploy using Azure CLI:

```bash
# Login to Azure
az login

# Deploy to subscription
az deployment sub create \
  --location "East US" \
  --template-file bicep/main.bicep \
  --parameters bicep/bicep.parameters.bicepparam \
  --name "cost-dashboard-$(date +%Y%m%d%H%M%S)"
```

### 7. Verify Deployment

Check the GitHub Actions logs for deployment status. After successful deployment, you should see:

- Resource group: `rg-cost-dashboard-{environment}`
- Storage account for cost data
- Function app for data processing
- Azure dashboard for visualization
- Budget and alerts configured

## Usage

### Automated Reports
The system automatically generates cost reports:
- **Daily**: Every day at 8 AM UTC
- **Weekly**: Every Monday at 8 AM UTC  
- **Monthly**: First day of month at 8 AM UTC

### Manual Report Generation

#### Using GitHub Actions
1. Go to Actions tab in your repository
2. Select "Cost Reporting" workflow
3. Click "Run workflow"
4. Choose environment and report type

#### Using PowerShell Script
```powershell
.\scripts\Generate-CostReport.ps1 -SubscriptionId "YOUR_SUBSCRIPTION_ID" -Environment "dev" -ReportType "daily"
```

#### Using Python Script
```bash
python scripts/generate-cost-report.py
```

### Accessing the Dashboard

#### Azure Portal Dashboard
1. Login to Azure Portal
2. Navigate to Dashboards
3. Find "Cost Analysis Dashboard - {environment}"

#### Web Dashboard
1. Open `dashboard/index.html` in a web browser
2. Or deploy to a web server/Azure Static Web Apps

## Monitoring Multiple Projects Efficiently

### Strategy 1: Resource Group Based Tracking
- Create separate resource groups per project
- Use consistent naming: `rg-{project}-{environment}`
- Apply project tags to all resources

### Strategy 2: Tag-Based Tracking
```json
{
  "Project": "ProjectA",
  "Environment": "Production", 
  "CostCenter": "Engineering",
  "Owner": "team@company.com"
}
```

### Strategy 3: Subscription-Based Tracking
- Separate subscriptions per major project
- Deploy cost dashboard in each subscription
- Aggregate reports centrally

## Cost Optimization Tips

1. **Set up Budget Alerts**: Configure budgets at 50%, 80%, and 100% thresholds
2. **Regular Reviews**: Schedule weekly cost reviews with project teams
3. **Tagging Strategy**: Implement consistent resource tagging
4. **Automated Cleanup**: Use Azure Automation for resource cleanup
5. **Right-sizing**: Monitor underutilized resources

## Troubleshooting

### Common Issues

#### 1. Permission Errors
```
Error: Insufficient permissions to query cost data
```
**Solution**: Ensure service principal has "Cost Management Reader" role

#### 2. No Cost Data
```
Warning: No cost data found
```
**Solutions**: 
- Check if resources exist in the subscription
- Verify date range in query
- Ensure resources have been running long enough to generate costs

#### 3. Deployment Failures
**Solution**: Check GitHub Actions logs for specific errors

### Support

For issues and questions:
1. Check GitHub Issues for known problems
2. Review Azure Cost Management documentation
3. Contact your Azure administrator

## Next Steps

1. **Customize Dashboards**: Modify charts and metrics for your needs
2. **Add More Environments**: Extend configuration for additional environments
3. **Integrate with Other Tools**: Connect to Power BI, Grafana, or other monitoring tools
4. **Automation**: Add automated cost optimization rules
