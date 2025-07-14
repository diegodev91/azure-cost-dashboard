#!/usr/bin/env python3
"""
Email Cost Report Sender

This script sends cost reports via email using SMTP.
"""

import os
import json
import smtplib
import glob
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class EmailReportSender:
    def __init__(self, smtp_server, smtp_port, username, password):
        self.smtp_server = smtp_server
        self.smtp_port = int(smtp_port)
        self.username = username
        self.password = password

    def send_cost_report(self, recipients, environment, report_type):
        """Send cost report via email"""
        try:
            # Find the latest report files
            report_files = self._find_latest_reports(environment, report_type)
            
            if not report_files:
                logger.warning(f"No report files found for {environment} {report_type}")
                return

            # Load summary data
            summary_data = self._load_summary_data(environment, report_type)
            
            # Create email message
            msg = MIMEMultipart()
            msg['From'] = self.username
            msg['To'] = ', '.join(recipients)
            msg['Subject'] = f"Azure Cost Report - {environment.upper()} ({report_type.title()}) - {datetime.now().strftime('%Y-%m-%d')}"
            
            # Create email body
            body = self._create_email_body(summary_data, environment, report_type)
            msg.attach(MIMEText(body, 'html'))
            
            # Attach report files
            for file_path in report_files:
                self._attach_file(msg, file_path)
            
            # Send email
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.username, self.password)
            
            text = msg.as_string()
            server.sendmail(self.username, recipients, text)
            server.quit()
            
            logger.info(f"Cost report email sent successfully to {', '.join(recipients)}")
            
        except Exception as e:
            logger.error(f"Error sending email report: {e}")

    def _find_latest_reports(self, environment, report_type):
        """Find the latest report files"""
        report_files = []
        
        # Find all report files for this environment and report type
        patterns = [
            f'reports/cost_data_{environment}_{report_type}_*.csv',
            f'reports/cost_summary_{environment}_{report_type}_*.json',
            f'reports/cost_charts_{environment}_{report_type}_*.png'
        ]
        
        for pattern in patterns:
            files = glob.glob(pattern)
            if files:
                # Get the most recent file
                latest_file = max(files, key=os.path.getctime)
                report_files.append(latest_file)
        
        return report_files

    def _load_summary_data(self, environment, report_type):
        """Load summary data from JSON file"""
        try:
            summary_files = glob.glob(f'reports/cost_summary_{environment}_{report_type}_*.json')
            if summary_files:
                latest_summary = max(summary_files, key=os.path.getctime)
                with open(latest_summary, 'r') as f:
                    return json.load(f)
        except Exception as e:
            logger.error(f"Error loading summary data: {e}")
        
        return {}

    def _create_email_body(self, summary_data, environment, report_type):
        """Create HTML email body"""
        total_cost = summary_data.get('total_cost', 0)
        avg_daily_cost = summary_data.get('average_daily_cost', 0)
        rg_count = summary_data.get('resource_group_count', 0)
        service_count = summary_data.get('service_count', 0)
        top_rgs = summary_data.get('top_resource_groups', {})
        top_services = summary_data.get('top_services', {})
        
        html_body = f"""
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; }}
                .header {{ background-color: #0078d4; color: white; padding: 20px; text-align: center; }}
                .content {{ padding: 20px; }}
                .summary {{ background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; }}
                .metric {{ display: inline-block; margin: 10px 20px; text-align: center; }}
                .metric-value {{ font-size: 24px; font-weight: bold; color: #0078d4; }}
                .metric-label {{ font-size: 14px; color: #666; }}
                table {{ border-collapse: collapse; width: 100%; margin: 20px 0; }}
                th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
                th {{ background-color: #f2f2f2; }}
                .cost {{ text-align: right; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Azure Cost Report</h1>
                <p>{environment.upper()} Environment - {report_type.title()} Report</p>
                <p>Generated on {datetime.now().strftime('%B %d, %Y at %I:%M %p')}</p>
            </div>
            
            <div class="content">
                <div class="summary">
                    <h2>Cost Summary</h2>
                    <div class="metric">
                        <div class="metric-value">${total_cost:.2f}</div>
                        <div class="metric-label">Total Cost</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">${avg_daily_cost:.2f}</div>
                        <div class="metric-label">Avg Daily Cost</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">{rg_count}</div>
                        <div class="metric-label">Resource Groups</div>
                    </div>
                    <div class="metric">
                        <div class="metric-value">{service_count}</div>
                        <div class="metric-label">Services</div>
                    </div>
                </div>
                
                <h3>Top Resource Groups by Cost</h3>
                <table>
                    <tr><th>Resource Group</th><th>Cost</th></tr>
        """
        
        for rg, cost in list(top_rgs.items())[:5]:
            html_body += f'<tr><td>{rg}</td><td class="cost">${cost:.2f}</td></tr>'
        
        html_body += """
                </table>
                
                <h3>Top Services by Cost</h3>
                <table>
                    <tr><th>Service</th><th>Cost</th></tr>
        """
        
        for service, cost in list(top_services.items())[:5]:
            html_body += f'<tr><td>{service}</td><td class="cost">${cost:.2f}</td></tr>'
        
        html_body += """
                </table>
                
                <p><strong>Note:</strong> Detailed reports and visualizations are attached to this email.</p>
                
                <hr>
                <p style="font-size: 12px; color: #666;">
                    This report was automatically generated by the Azure Cost Dashboard system.
                    For questions or issues, please contact your system administrator.
                </p>
            </div>
        </body>
        </html>
        """
        
        return html_body

    def _attach_file(self, msg, file_path):
        """Attach file to email message"""
        try:
            with open(file_path, "rb") as attachment:
                part = MIMEBase('application', 'octet-stream')
                part.set_payload(attachment.read())
            
            encoders.encode_base64(part)
            
            filename = os.path.basename(file_path)
            part.add_header(
                'Content-Disposition',
                f'attachment; filename= {filename}'
            )
            
            msg.attach(part)
            
        except Exception as e:
            logger.error(f"Error attaching file {file_path}: {e}")

def main():
    # Get environment variables
    smtp_server = os.getenv('SMTP_SERVER')
    smtp_port = os.getenv('SMTP_PORT', '587')
    username = os.getenv('SMTP_USERNAME')
    password = os.getenv('SMTP_PASSWORD')
    recipients_str = os.getenv('REPORT_RECIPIENTS', '')
    environment = os.getenv('ENVIRONMENT', 'dev')
    report_type = os.getenv('REPORT_TYPE', 'daily')
    
    if not all([smtp_server, username, password, recipients_str]):
        logger.error("SMTP configuration is incomplete")
        return
    
    recipients = [email.strip() for email in recipients_str.split(',') if email.strip()]
    
    if not recipients:
        logger.error("No valid email recipients found")
        return
    
    # Send email report
    sender = EmailReportSender(smtp_server, smtp_port, username, password)
    sender.send_cost_report(recipients, environment, report_type)

if __name__ == "__main__":
    main()
