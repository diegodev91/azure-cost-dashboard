# Azure Cost Dashboard

[![Deploy Infrastructure](https://github.com/YOUR_USERNAME/azure-cost-dashboard/actions/workflows/deploy-infrastructure.yml/badge.svg)](https://github.com/YOUR_USERNAME/azure-cost-dashboard/actions/workflows/deploy-infrastructure.yml)
[![Cost Reporting](https://github.com/YOUR_USERNAME/azure-cost-dashboard/actions/workflows/cost-reporting.yml/badge.svg)](https://github.com/YOUR_USERNAME/azure-cost-dashboard/actions/workflows/cost-reporting.yml)

An enterprise-grade Azure cost tracking solution using **100% Azure native capabilities**. Deploy automated cost monitoring, budgets, alerts, and dashboards across multiple environments without any external dependencies.

## 🚀 Quick Deploy

1. **Fork this repository**
2. **Configure GitHub secrets** (see setup guide below)
3. **Push to main branch** - deployment starts automatically!
4. **Access dashboards** in Azure Portal

## 🎯 What Gets Created

### Azure Native Components
- 🎛️ **Azure Portal Dashboard** - Native cost visualization widgets
- 📊 **Azure Monitor Workbook** - Interactive cost analysis with KQL queries  
- 💰 **Cost Management Integration** - Automated budgets, alerts, forecasting
- 📧 **Email Notifications** - Budget threshold alerts (80%, 100%)
- 📈 **Log Analytics** - 30-day cost data retention and custom queries

### Automation
- ⚡ **GitHub Actions** - Automated deployment and reporting
- 📅 **Scheduled Reports** - Daily, weekly, monthly cost analysis
- 🐍 **Python Scripts** - Custom report generation and email automation
- 💻 **PowerShell Scripts** - Windows-based cost analysis tools

## Project Structure

```
cost-dashboard/
├── bicep/                     # Infrastructure as Code
│   ├── main.bicep            # Main deployment template
│   └── modules/              # Modular Bicep templates
├── .github/workflows/        # GitHub Actions workflows
├── scripts/                  # Cost reporting automation
├── config/                   # Configuration files
└── docs/                     # Documentation
```

## Prerequisites

- Azure subscription with Cost Management permissions
- GitHub repository with Actions enabled
- Azure CLI or PowerShell Az module

## 🛠️ Setup Instructions

### Step 1: Fork Repository
Fork this repository to your GitHub account.

### Step 2: Create Azure Service Principal
```bash
# Create service principal with required permissions
az ad sp create-for-rbac \
  --name "cost-dashboard-sp" \
  --role "Contributor" \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID" \
  --sdk-auth

# Add Cost Management Reader role
az role assignment create \
  --assignee SERVICE_PRINCIPAL_CLIENT_ID \
  --role "Cost Management Reader" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

### Step 3: Configure GitHub Secrets
Add these secrets in your repository: **Settings** → **Secrets and variables** → **Actions**

| Secret Name | Description | Required |
|-------------|-------------|----------|
| `AZURE_CLIENT_ID` | Service Principal Application ID | ✅ |
| `AZURE_TENANT_ID` | Azure AD Tenant ID | ✅ |
| `AZURE_SUBSCRIPTION_ID` | Target Azure Subscription ID | ✅ |
| `SMTP_SERVER` | Email server for reports (optional) | ❌ |
| `SMTP_USERNAME` | Email username (optional) | ❌ |
| `SMTP_PASSWORD` | Email password (optional) | ❌ |

### Step 4: Configure GitHub Variables  
Add these variables in: **Settings** → **Secrets and variables** → **Actions** → **Variables**

| Variable Name | Description | Default | Example |
|---------------|-------------|---------|---------|
| `AZURE_LOCATION` | Azure region | `East US` | `West US 2` |
| `BUDGET_AMOUNT` | Monthly budget (USD) | `1000` | `5000` |
| `ALERT_EMAILS` | JSON array of emails | `["admin@example.com"]` | `["finance@company.com"]` |
| `SMTP_ENABLED` | Enable email reports | `false` | `true` |
| `REPORT_RECIPIENTS` | Email list for reports | | `admin@company.com,finance@company.com` |

### Step 5: Customize Parameters
1. Copy `bicep/bicep.parameters.example.bicepparam` to `bicep/bicep.parameters.bicepparam`
2. Update with your values:
```bicep
param environment = 'prod'  // or 'dev', 'staging'
param location = 'East US'
param budgetAmount = 5000
param alertEmails = [
  'finance@yourcompany.com'
  'engineering@yourcompany.com'
]
```

### Step 6: Deploy
```bash
git add .
git commit -m "Configure cost dashboard for production"
git push origin main
```

## 📊 Accessing Your Dashboards

### Azure Portal Dashboard
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Dashboards**
3. Select **"dashboard-cost-{environment}"**

### Cost Management Tools
1. **Cost Management + Billing** → Comprehensive cost analysis
2. **Monitor** → **Workbooks** → Interactive cost analysis
3. **Budgets** → Budget monitoring and alerts

## 🔧 Resource Group Strategies

Choose your approach for tracking costs across projects:

### Option 1: Naming Convention (Recommended)
```
rg-{project}-{environment}-{location}
Examples:
- rg-webapp-prod-eastus
- rg-database-dev-westus2
- rg-analytics-staging-centralus
```

### Option 2: Tagging Strategy
```json
{
  "Project": "ECommerce",
  "Environment": "Production",
  "CostCenter": "Engineering",
  "Owner": "team@company.com"
}
```

### Option 3: Subscription Separation
- Separate subscriptions for major projects
- Deploy cost dashboard in each subscription

## 📈 Features

- ✅ **Multi-environment support** (dev, staging, prod)
- ✅ **Automated budget alerts** (configurable thresholds)
- ✅ **Email notifications** with cost summaries
- ✅ **Resource group cost tracking**
- ✅ **Service-level cost analysis**
- ✅ **Daily/weekly/monthly reporting**
- ✅ **Cost trend forecasting**
- ✅ **Export capabilities** (CSV, JSON, charts)

## 🛡️ Security & Compliance

- 🔐 **No sensitive data in repository**
- 🔐 **GitHub secrets for credentials**
- 🔐 **Service principal with minimal permissions**
- 🔐 **Azure native security model**
- 🔐 **HTTPS for all communications**

## 📚 Documentation

- [Setup Guide](docs/SETUP.md) - Detailed deployment instructions
- [Architecture](docs/ARCHITECTURE.md) - Technical architecture overview
- [Azure Native Dashboard](docs/AZURE_NATIVE_DASHBOARD.md) - Dashboard features
- [Resource Group Strategies](docs/RESOURCE_GROUP_STRATEGIES.md) - Cost tracking approaches

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with your Azure environment
5. Submit a pull request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- 📖 Check the [documentation](docs/) for detailed guides
- 🐛 Report issues using GitHub Issues
- 💬 Discussions in GitHub Discussions
- 📧 For security issues, email privately

## 🌟 Acknowledgments

- Built with Azure Bicep and native Azure services
- Powered by GitHub Actions for automation
- Uses Azure Cost Management APIs for data
- Designed for enterprise-scale cost monitoring

---

**Ready to deploy?** Follow the setup instructions above and start monitoring your Azure costs in minutes! 🚀
