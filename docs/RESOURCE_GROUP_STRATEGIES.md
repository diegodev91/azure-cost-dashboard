# Resource Group Monitoring Strategies

Since we've removed the `resourceGroupsToMonitor` parameter from the main Bicep template (as it wasn't being used effectively), here are the recommended approaches for monitoring costs across different resource groups and projects:

## 📊 Strategy 1: Resource Group Naming Convention (Recommended)

### Naming Pattern
```
rg-{project}-{environment}-{location}
```

### Examples
```
Production Environment:
- rg-webapp-prod-eastus
- rg-database-prod-eastus  
- rg-storage-prod-eastus
- rg-monitoring-prod-eastus

Development Environment:
- rg-webapp-dev-westus2
- rg-database-dev-westus2
- rg-storage-dev-westus2

Staging Environment:
- rg-webapp-staging-centralus
- rg-database-staging-centralus
```

### Benefits
- ✅ Easy to identify project and environment
- ✅ Automatic cost segregation in reports
- ✅ Supports multiple regions
- ✅ Works with Azure Cost Management filters

### Implementation
The cost reporting scripts will automatically group costs by resource group name, making it easy to see spending per project and environment.

## 🏷️ Strategy 2: Comprehensive Tagging

### Tag Schema
```json
{
  "Project": "ECommerce",
  "Environment": "Production", 
  "CostCenter": "Engineering",
  "Owner": "ecommerce-team@company.com",
  "BusinessUnit": "Digital",
  "Application": "WebStore",
  "Purpose": "Frontend"
}
```

### Tag Examples by Project
```json
// Project 1: E-commerce Platform
{
  "Project": "ECommerce",
  "Environment": "Production",
  "CostCenter": "Engineering", 
  "Owner": "ecommerce@company.com",
  "BusinessUnit": "Digital"
}

// Project 2: Data Analytics
{
  "Project": "Analytics",
  "Environment": "Production", 
  "CostCenter": "DataScience",
  "Owner": "data-team@company.com",
  "BusinessUnit": "Operations"
}

// Shared Services
{
  "Project": "SharedServices",
  "Environment": "Production",
  "CostCenter": "Platform",
  "Owner": "platform-team@company.com", 
  "BusinessUnit": "Engineering"
}
```

### Benefits
- ✅ Detailed cost attribution
- ✅ Cross-cutting analysis (by team, cost center, etc.)
- ✅ Supports complex organizational structures
- ✅ Works across subscriptions

## 🔧 Strategy 3: Subscription-Based Separation

### Subscription Structure
```
Company Azure Account
├── Subscription: "Project-ECommerce-Prod" 
├── Subscription: "Project-ECommerce-Dev"
├── Subscription: "Project-Analytics-Prod"
├── Subscription: "Project-Analytics-Dev"
└── Subscription: "Shared-Services"
```

### Benefits
- ✅ Complete cost isolation
- ✅ Independent billing
- ✅ Separate security boundaries
- ✅ Clear ownership

### Implementation
Deploy the cost dashboard in each subscription, then aggregate reports using the GitHub Actions workflows.

## 🚀 Hybrid Approach (Best Practice)

Combine all three strategies for maximum effectiveness:

### Level 1: Subscription (Major Projects)
```
- Subscription: "ProjectA-Production"
- Subscription: "ProjectA-Development" 
- Subscription: "ProjectB-Production"
- Subscription: "SharedServices"
```

### Level 2: Resource Group Naming
```
Within each subscription:
- rg-frontend-prod-eastus
- rg-backend-prod-eastus
- rg-database-prod-eastus
- rg-monitoring-prod-eastus
```

### Level 3: Consistent Tagging
```json
{
  "Project": "ProjectA",
  "Component": "Frontend",
  "Environment": "Production",
  "CostCenter": "Engineering",
  "Owner": "projecta-team@company.com"
}
```

## 📈 Cost Tracking Implementation

### 1. Update Configuration
Edit `config/config.json` to match your structure:

```json
{
  "environments": {
    "dev": {
      "subscriptionId": "dev-subscription-id",
      "projects": [
        {
          "name": "ECommerce",
          "resourceGroups": ["rg-webapp-dev-*", "rg-database-dev-*"],
          "tags": {"Project": "ECommerce"}
        },
        {
          "name": "Analytics", 
          "resourceGroups": ["rg-analytics-dev-*"],
          "tags": {"Project": "Analytics"}
        }
      ]
    }
  }
}
```

### 2. Customize Report Scripts
The Python scripts can be enhanced to filter by your specific criteria:

```python
# Filter by resource group pattern
def get_project_costs(cost_data, project_pattern):
    return cost_data[cost_data['ResourceGroup'].str.contains(project_pattern)]

# Filter by tags
def get_costs_by_tag(cost_data, tag_key, tag_value):
    return cost_data[cost_data['Tags'].str.contains(f'"{tag_key}":"{tag_value}"')]
```

### 3. Dashboard Customization
Update the web dashboard to show project-specific views:

```javascript
// Add project filter
const projectFilter = document.getElementById('projectSelect');
projectFilter.addEventListener('change', (e) => {
    this.filterByProject(e.target.value);
});
```

## 🔍 Monitoring Different Resource Groups

### Azure Cost Management Queries
Use these queries in Azure Cost Management or the API:

#### By Resource Group Pattern
```bash
# Get costs for all webapp resource groups
az costmanagement query \
  --type "ActualCost" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --timeframe "MonthToDate" \
  --dataset '{"filter":{"dimensions":{"name":"ResourceGroup","operator":"Contains","values":["webapp"]}}}'
```

#### By Tag
```bash
# Get costs by project tag
az costmanagement query \
  --type "ActualCost" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --timeframe "MonthToDate" \
  --dataset '{"filter":{"tags":{"name":"Project","operator":"In","values":["ECommerce"]}}}'
```

### Custom Budgets per Project
Create separate budgets for each project:

```bash
# Create budget for ECommerce project
az consumption budget create \
  --budget-name "Budget-ECommerce-Prod" \
  --amount 2000 \
  --category "Cost" \
  --time-grain "Monthly" \
  --start-date "2024-01-01" \
  --end-date "2025-12-31" \
  --resource-group-filter "rg-webapp-prod-*" "rg-database-prod-*"
```

## 📊 Reporting Examples

### Project-Level Cost Report
```python
# Generate project-specific report
def generate_project_report(project_name):
    cost_data = get_cost_data()
    project_data = cost_data[cost_data['ResourceGroup'].str.contains(project_name)]
    
    return {
        'project': project_name,
        'total_cost': project_data['PreTaxCost'].sum(),
        'resource_groups': project_data.groupby('ResourceGroup')['PreTaxCost'].sum().to_dict(),
        'services': project_data.groupby('ServiceName')['PreTaxCost'].sum().to_dict()
    }
```

### Multi-Project Comparison
```python
# Compare costs across projects
def compare_projects():
    projects = ['ECommerce', 'Analytics', 'Platform']
    comparison = {}
    
    for project in projects:
        comparison[project] = generate_project_report(project)
    
    return comparison
```

This approach gives you maximum flexibility to track costs at whatever granularity makes sense for your organization, whether by project, environment, team, or cost center.
