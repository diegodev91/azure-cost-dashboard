# GitHub Actions Deployment Guide

This guide explains how to set up and deploy the Azure Cost Dashboard using GitHub Actions.

## 🔐 Security First

This repository is designed to be **100% safe for public use**:
- ✅ No sensitive data in code
- ✅ All credentials stored in GitHub Secrets
- ✅ Service principal with minimal permissions
- ✅ No API keys or connection strings in files

## 🚀 Quick Setup

### 1. Fork/Clone Repository
```bash
# Option A: Fork on GitHub (recommended)
# Go to GitHub and fork this repository

# Option B: Clone and create new repo
git clone https://github.com/original-repo/azure-cost-dashboard.git
cd azure-cost-dashboard
# Create new repository on GitHub and update remote
```

### 2. Create Azure Service Principal
```bash
# Login to Azure
az login

# Create service principal (save the output!)
az ad sp create-for-rbac \
  --name "cost-dashboard-github-actions" \
  --role "Contributor" \
  --scopes "/subscriptions/YOUR_SUBSCRIPTION_ID" \
  --sdk-auth

# Add Cost Management Reader role
az role assignment create \
  --assignee <CLIENT_ID_FROM_ABOVE> \
  --role "Cost Management Reader" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"
```

### 3. Configure GitHub Secrets
Go to your repository: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

**Required Secrets:**
```
AZURE_CLIENT_ID=12345678-1234-1234-1234-123456789012
AZURE_TENANT_ID=87654321-4321-4321-4321-210987654321  
AZURE_SUBSCRIPTION_ID=11111111-2222-3333-4444-555555555555
```

**Optional Email Secrets (for automated reports):**
```
SMTP_SERVER=smtp.gmail.com
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

### 4. Configure GitHub Variables
Go to: **Settings** → **Secrets and variables** → **Actions** → **Variables**

```
AZURE_LOCATION=East US
BUDGET_AMOUNT=1000
ALERT_EMAILS=["admin@yourcompany.com","finance@yourcompany.com"]
SMTP_ENABLED=false
REPORT_RECIPIENTS=admin@yourcompany.com,finance@yourcompany.com
```

### 5. Customize Parameters
```bash
# Copy example parameters
cp bicep/bicep.parameters.example.bicepparam bicep/bicep.parameters.bicepparam

# Edit the file
nano bicep/bicep.parameters.bicepparam
```

Update with your values:
```bicep
using './main.bicep'

param environment = 'prod'
param location = 'East US'
param budgetAmount = 2000
param alertEmails = [
  'finance@yourcompany.com'
  'devops@yourcompany.com'
]
```

### 6. Deploy
```bash
git add .
git commit -m "Configure cost dashboard for deployment"
git push origin main
```

## 🔄 GitHub Actions Workflows

### Infrastructure Deployment Workflow
**File**: `.github/workflows/deploy-infrastructure.yml`

**Triggers**:
- Push to `main` branch (with Bicep changes)
- Manual workflow dispatch
- Pull requests (validation only)

**What it does**:
1. Validates Bicep templates
2. Creates Azure resources using Bicep
3. Outputs deployment information
4. Updates GitHub summary with resource details

### Cost Reporting Workflow  
**File**: `.github/workflows/cost-reporting.yml`

**Triggers**:
- Scheduled: Daily (8 AM UTC), Weekly (Monday 8 AM), Monthly (1st 8 AM)
- Manual workflow dispatch

**What it does**:
1. Generates cost reports using Python scripts
2. Creates charts and visualizations
3. Exports data to CSV/JSON formats
4. Sends email reports (if configured)
5. Archives reports as GitHub artifacts

## 🛠️ Workflow Customization

### Change Deployment Schedule
Edit `.github/workflows/cost-reporting.yml`:
```yaml
schedule:
  # Daily at 6 AM UTC instead of 8 AM
  - cron: '0 6 * * *'
  # Weekly on Wednesday instead of Monday
  - cron: '0 8 * * 3'
  # Monthly on 15th instead of 1st
  - cron: '0 8 15 * *'
```

### Multi-Environment Deployment
Create environment-specific parameter files:
```bash
# Development
cp bicep/bicep.parameters.example.bicepparam bicep/bicep.parameters.dev.bicepparam

# Staging
cp bicep/bicep.parameters.example.bicepparam bicep/bicep.parameters.staging.bicepparam

# Production
cp bicep/bicep.parameters.example.bicepparam bicep/bicep.parameters.prod.bicepparam
```

Use workflow dispatch to deploy to specific environments.

## 🔍 Monitoring Deployments

### Check Deployment Status
1. Go to **Actions** tab in your repository
2. View latest workflow runs
3. Check logs for any errors
4. Review deployment summaries

### View Deployed Resources
After successful deployment:
1. Check GitHub Actions summary for resource links
2. Go to Azure Portal → Resource Groups
3. Find `rg-cost-dashboard-{environment}`
4. Verify all resources are created

### Access Dashboards
1. Azure Portal → Dashboards → `dashboard-cost-{environment}`
2. Azure Portal → Monitor → Workbooks
3. Azure Portal → Cost Management + Billing

## 🚨 Troubleshooting

### Common Issues

#### 1. Authentication Errors
```
Error: Failed to authenticate with Azure
```
**Solution**: 
- Verify service principal credentials in GitHub secrets
- Ensure service principal has correct permissions
- Check subscription ID is correct

#### 2. Permission Denied
```
Error: Insufficient privileges to complete the operation  
```
**Solution**:
- Add "Cost Management Reader" role to service principal
- Verify service principal has "Contributor" role on subscription

#### 3. Location Not Available
```
Error: The location 'Region Name' is not available
```
**Solution**:
- Update `AZURE_LOCATION` variable to a valid region
- Check Azure region availability for your subscription

#### 4. Budget Creation Failed
```
Error: Budget creation failed
```
**Solution**:
- Ensure you have billing permissions
- Check if budget with same name already exists
- Verify subscription has Cost Management enabled

### Getting Help

1. **Check workflow logs**: Actions tab → Failed workflow → View logs
2. **Validate locally**: Run `az bicep build --file bicep/main.bicep`
3. **Test authentication**: Run `az account show` with service principal
4. **Review documentation**: Check docs/ folder for detailed guides

## 🔒 Security Best Practices

### Service Principal Security
- Use minimal required permissions
- Rotate credentials regularly (quarterly)
- Monitor Azure Activity Logs for unusual access
- Use Azure AD Conditional Access when possible

### GitHub Repository Security
- Enable branch protection on main branch
- Require pull request reviews for changes
- Enable security alerts and dependency scanning
- Use environment protection rules for production

### Cost Data Security
- Limit access to cost reports
- Review email recipient lists regularly
- Consider data retention policies
- Use secure channels for sensitive cost information

## 📊 Understanding Costs

The deployment creates minimal Azure resources:
- **Storage Account**: ~$1-5/month (depending on usage)
- **Function App**: ~$0-10/month (consumption plan)
- **Log Analytics**: ~$0-5/month (30-day retention)
- **Application Insights**: ~$0-2/month (basic monitoring)

Total estimated cost: **$5-25/month** depending on usage and data volume.

## 🎯 Next Steps

After successful deployment:
1. ✅ Verify dashboards are accessible in Azure Portal
2. ✅ Test budget alerts by reviewing email notifications
3. ✅ Customize cost analysis queries in Monitor Workbooks
4. ✅ Set up additional budgets for specific resource groups
5. ✅ Configure team access to cost management tools
6. ✅ Schedule regular cost reviews with stakeholders

## 📈 Scaling Up

For enterprise use:
- Deploy to multiple subscriptions
- Create environment-specific GitHub repositories
- Implement centralized cost aggregation
- Add custom Power BI reporting
- Integrate with existing monitoring systems

---

**Ready to deploy?** Follow the steps above and start monitoring your Azure costs with enterprise-grade automation! 🚀
