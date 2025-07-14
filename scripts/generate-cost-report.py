#!/usr/bin/env python3
"""
Azure Cost Report Generator

This script generates cost reports for Azure subscriptions and resource groups.
It uses the Azure Cost Management API to fetch cost data and generates various
report formats including CSV, JSON, and visualizations.
"""

import os
import json
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
from azure.identity import DefaultAzureCredential
from azure.mgmt.costmanagement import CostManagementClient
from azure.mgmt.resource import ResourceManagementClient
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class CostReportGenerator:
    def __init__(self, subscription_id):
        self.subscription_id = subscription_id
        self.credential = DefaultAzureCredential()
        self.cost_client = CostManagementClient(self.credential)
        self.resource_client = ResourceManagementClient(self.credential, subscription_id)
        
    def get_resource_groups(self):
        """Get list of resource groups in the subscription"""
        try:
            resource_groups = []
            for rg in self.resource_client.resource_groups.list():
                resource_groups.append({
                    'name': rg.name,
                    'location': rg.location,
                    'tags': rg.tags or {}
                })
            return resource_groups
        except Exception as e:
            logger.error(f"Error fetching resource groups: {e}")
            return []

    def get_cost_data(self, scope, time_period='month'):
        """Fetch cost data for a given scope"""
        try:
            # Define time period
            end_date = datetime.now().date()
            if time_period == 'month':
                start_date = end_date.replace(day=1)
            elif time_period == 'week':
                start_date = end_date - timedelta(days=7)
            else:  # daily
                start_date = end_date - timedelta(days=1)

            # Query definition
            query_definition = {
                "type": "ActualCost",
                "timeframe": "Custom",
                "timePeriod": {
                    "from": start_date.isoformat(),
                    "to": end_date.isoformat()
                },
                "dataset": {
                    "granularity": "Daily",
                    "aggregation": {
                        "totalCost": {
                            "name": "PreTaxCost",
                            "function": "Sum"
                        }
                    },
                    "grouping": [
                        {
                            "type": "Dimension",
                            "name": "ResourceGroup"
                        },
                        {
                            "type": "Dimension", 
                            "name": "ServiceName"
                        }
                    ]
                }
            }

            # Execute query
            result = self.cost_client.query.usage(scope=scope, parameters=query_definition)
            return self._process_cost_result(result)
            
        except Exception as e:
            logger.error(f"Error fetching cost data for scope {scope}: {e}")
            return []

    def _process_cost_result(self, result):
        """Process the cost management API result"""
        cost_data = []
        
        if hasattr(result, 'rows') and result.rows:
            columns = [col.name for col in result.columns]
            
            for row in result.rows:
                cost_record = dict(zip(columns, row))
                cost_data.append(cost_record)
                
        return cost_data

    def generate_summary_report(self, environment, report_type):
        """Generate a comprehensive cost summary report"""
        logger.info(f"Generating {report_type} cost report for {environment} environment")
        
        # Get subscription scope
        subscription_scope = f"/subscriptions/{self.subscription_id}"
        
        # Fetch cost data
        cost_data = self.get_cost_data(subscription_scope, report_type)
        
        if not cost_data:
            logger.warning("No cost data found")
            return
            
        # Convert to DataFrame for analysis
        df = pd.DataFrame(cost_data)
        
        # Generate reports
        os.makedirs('reports', exist_ok=True)
        
        # Save raw data
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        csv_file = f'reports/cost_data_{environment}_{report_type}_{timestamp}.csv'
        json_file = f'reports/cost_data_{environment}_{report_type}_{timestamp}.json'
        
        df.to_csv(csv_file, index=False)
        df.to_json(json_file, orient='records', indent=2)
        
        # Generate visualizations
        self._create_visualizations(df, environment, report_type, timestamp)
        
        # Generate summary statistics
        self._generate_summary_stats(df, environment, report_type, timestamp)
        
        logger.info(f"Reports generated successfully for {environment}")

    def _create_visualizations(self, df, environment, report_type, timestamp):
        """Create cost visualization charts"""
        try:
            # Set up the plotting style
            plt.style.use('default')
            sns.set_palette("husl")
            
            # Create figure with subplots
            fig, axes = plt.subplots(2, 2, figsize=(16, 12))
            fig.suptitle(f'Azure Cost Analysis - {environment.upper()} ({report_type.title()})', fontsize=16)
            
            # Cost by Resource Group
            if 'ResourceGroup' in df.columns and 'PreTaxCost' in df.columns:
                rg_costs = df.groupby('ResourceGroup')['PreTaxCost'].sum().sort_values(ascending=False).head(10)
                rg_costs.plot(kind='bar', ax=axes[0,0])
                axes[0,0].set_title('Top 10 Resource Groups by Cost')
                axes[0,0].set_ylabel('Cost ($)')
                axes[0,0].tick_params(axis='x', rotation=45)
            
            # Cost by Service
            if 'ServiceName' in df.columns and 'PreTaxCost' in df.columns:
                service_costs = df.groupby('ServiceName')['PreTaxCost'].sum().sort_values(ascending=False).head(10)
                service_costs.plot(kind='bar', ax=axes[0,1])
                axes[0,1].set_title('Top 10 Services by Cost')
                axes[0,1].set_ylabel('Cost ($)')
                axes[0,1].tick_params(axis='x', rotation=45)
            
            # Daily cost trend
            if 'UsageDate' in df.columns and 'PreTaxCost' in df.columns:
                daily_costs = df.groupby('UsageDate')['PreTaxCost'].sum().sort_index()
                daily_costs.plot(kind='line', ax=axes[1,0], marker='o')
                axes[1,0].set_title('Daily Cost Trend')
                axes[1,0].set_ylabel('Cost ($)')
                axes[1,0].tick_params(axis='x', rotation=45)
            
            # Cost distribution pie chart
            if 'ResourceGroup' in df.columns and 'PreTaxCost' in df.columns:
                rg_costs_pie = df.groupby('ResourceGroup')['PreTaxCost'].sum().sort_values(ascending=False).head(8)
                others = df.groupby('ResourceGroup')['PreTaxCost'].sum().sort_values(ascending=False)[8:].sum()
                if others > 0:
                    rg_costs_pie['Others'] = others
                
                axes[1,1].pie(rg_costs_pie.values, labels=rg_costs_pie.index, autopct='%1.1f%%')
                axes[1,1].set_title('Cost Distribution by Resource Group')
            
            plt.tight_layout()
            
            # Save the visualization
            chart_file = f'reports/cost_charts_{environment}_{report_type}_{timestamp}.png'
            plt.savefig(chart_file, dpi=300, bbox_inches='tight')
            plt.close()
            
            logger.info(f"Visualizations saved to {chart_file}")
            
        except Exception as e:
            logger.error(f"Error creating visualizations: {e}")

    def _generate_summary_stats(self, df, environment, report_type, timestamp):
        """Generate summary statistics"""
        try:
            stats = {
                'environment': environment,
                'report_type': report_type,
                'generated_at': datetime.now().isoformat(),
                'total_cost': float(df['PreTaxCost'].sum()) if 'PreTaxCost' in df.columns else 0,
                'average_daily_cost': float(df.groupby('UsageDate')['PreTaxCost'].sum().mean()) if 'UsageDate' in df.columns and 'PreTaxCost' in df.columns else 0,
                'resource_group_count': df['ResourceGroup'].nunique() if 'ResourceGroup' in df.columns else 0,
                'service_count': df['ServiceName'].nunique() if 'ServiceName' in df.columns else 0,
                'top_resource_groups': df.groupby('ResourceGroup')['PreTaxCost'].sum().sort_values(ascending=False).head(5).to_dict() if 'ResourceGroup' in df.columns and 'PreTaxCost' in df.columns else {},
                'top_services': df.groupby('ServiceName')['PreTaxCost'].sum().sort_values(ascending=False).head(5).to_dict() if 'ServiceName' in df.columns and 'PreTaxCost' in df.columns else {}
            }
            
            summary_file = f'reports/cost_summary_{environment}_{report_type}_{timestamp}.json'
            with open(summary_file, 'w') as f:
                json.dump(stats, f, indent=2)
                
            logger.info(f"Summary statistics saved to {summary_file}")
            
        except Exception as e:
            logger.error(f"Error generating summary statistics: {e}")

def main():
    # Get environment variables
    subscription_id = os.getenv('AZURE_SUBSCRIPTION_ID')
    environment = os.getenv('ENVIRONMENT', 'dev')
    report_type = os.getenv('REPORT_TYPE', 'daily')
    
    if not subscription_id:
        logger.error("AZURE_SUBSCRIPTION_ID environment variable is required")
        return
    
    # Generate report
    generator = CostReportGenerator(subscription_id)
    generator.generate_summary_report(environment, report_type)

if __name__ == "__main__":
    main()
