# Azure Cost Dashboard - Quick Start

This project provides a comprehensive solution for tracking Azure costs across multiple resource groups and environments using Bicep templates and GitHub Actions.

## 🚀 Quick Start

1. **Configure Azure Credentials**
   ```bash
   # Create service principal
   az ad sp create-for-rbac --name "cost-dashboard-sp" --role "Contributor" --scopes "/subscriptions/<YOUR_SUBSCRIPTION_ID>" --sdk-auth
   ```

2. **Set GitHub Secrets**
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

3. **Configure Variables**
   - `AZURE_LOCATION`: East US
   - `BUDGET_AMOUNT`: 1000
   - `ALERT_EMAILS`: ["admin@company.com"]

4. **Deploy Infrastructure**
   ```bash
   git push origin main  # Triggers automatic deployment
   ```

5. **Access Dashboard**
   - Azure Portal: Navigate to Dashboards
   - Web Interface: Open `dashboard/index.html`

## 📊 Features

- ✅ **Multi-environment support** (dev, staging, prod)
- ✅ **Automated daily/weekly/monthly reports**
- ✅ **Budget alerts and notifications**
- ✅ **Visual dashboards and charts**
- ✅ **Email reporting capabilities**
- ✅ **Resource group cost tracking**
- ✅ **Service-level cost analysis**

## 📂 Project Structure

```
cost-dashboard/
├── bicep/                  # Infrastructure as Code
│   ├── main.bicep         # Main deployment template
│   └── modules/           # Modular Bicep templates
├── .github/workflows/     # GitHub Actions
│   ├── deploy-infrastructure.yml
│   └── cost-reporting.yml
├── scripts/               # Automation scripts
│   ├── generate-cost-report.py
│   ├── send-email-report.py
│   └── Generate-CostReport.ps1
├── dashboard/             # Web dashboard
│   ├── index.html
│   └── js/dashboard.js
├── config/                # Configuration files
└── docs/                  # Documentation
```

## 🎯 Use Cases

### Scenario 1: Multiple Projects, Single Subscription
- Track costs by resource group naming convention
- Example: `rg-ecommerce-prod`, `rg-analytics-dev`, `rg-shared-staging`

### Scenario 2: Project-based Subscriptions
- Deploy dashboard in each subscription
- Centralize reporting through aggregation

### Scenario 3: Department/Team Cost Allocation
- Use tagging strategy for cost attribution
- Generate reports by cost center or team

## 🔧 Efficient Cost Tracking Strategies

### 1. Resource Group Strategy (Recommended)
```
rg-{project}-{environment}-{region}
rg-webapp-prod-eastus
rg-database-staging-westus2
```

### 2. Tagging Strategy
```json
{
  "Project": "ECommerce",
  "Environment": "Production",
  "CostCenter": "Engineering", 
  "Owner": "team@company.com"
}
```

### 3. Subscription Strategy
- Separate billing for major initiatives
- Easier cost isolation
- Department-specific subscriptions

## 📈 Cost Optimization Tips

1. **Set Multiple Budget Thresholds**: 50%, 80%, 100%
2. **Regular Review Cycles**: Weekly team reviews
3. **Automated Cleanup**: Remove unused resources
4. **Right-sizing**: Monitor underutilized resources
5. **Reserved Instances**: For predictable workloads

## 🛠️ Customization

### Add New Environments
Update `config/config.json`:
```json
{
  "environments": {
    "qa": {
      "subscriptionId": "YOUR_QA_SUBSCRIPTION_ID",
      "location": "West US 2",
      "budgetAmount": 750,
      "alertEmails": ["qa-team@company.com"]
    }
  }
}
```

### Modify Report Schedule
Edit `.github/workflows/cost-reporting.yml`:
```yaml
schedule:
  - cron: '0 6 * * *'  # 6 AM daily instead of 8 AM
```

### Custom Dashboard
Modify `dashboard/js/dashboard.js` to add:
- New chart types
- Additional metrics
- Custom filters

## 📧 Email Reports

Enable email reporting by setting:
- `SMTP_ENABLED`: true
- `SMTP_SERVER`: smtp.gmail.com
- `SMTP_USERNAME`: your-email@gmail.com
- `SMTP_PASSWORD`: your-app-password

## 🔍 Monitoring

### GitHub Actions Status
- Check Actions tab for deployment status
- Review workflow logs for issues

### Azure Monitoring
- Budget alerts in Azure Portal
- Cost Management + Billing blade
- Application Insights for Function App

## 🆘 Troubleshooting

### Common Issues:

1. **Permission Denied**
   - Ensure service principal has "Cost Management Reader" role
   - Check subscription-level permissions

2. **No Cost Data**
   - Verify resources exist and are generating costs
   - Check date ranges in queries

3. **Email Not Sending**
   - Verify SMTP credentials
   - Check firewall/security settings

### Getting Help:
- Review logs in GitHub Actions
- Check Azure Activity Log
- Consult documentation in `/docs`

## 📝 Next Steps

1. **Review Setup Guide**: `docs/SETUP.md`
2. **Understand Architecture**: `docs/ARCHITECTURE.md`
3. **Customize for Your Needs**: Modify templates and scripts
4. **Set Up Monitoring**: Configure alerts and dashboards
5. **Train Your Team**: Share dashboard access and reports

---

**Need help?** Check the documentation in the `/docs` folder or review the GitHub Issues for common problems and solutions.
