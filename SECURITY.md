# Security Policy

## Supported Versions

We support the latest version of the Azure Cost Dashboard project with security updates.

| Version | Supported          |
| ------- | ------------------ |
| Latest  | :white_check_mark: |
| < Latest| :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability, please report it responsibly:

### For Security Issues
- **DO NOT** create a public GitHub issue for security vulnerabilities
- Email security concerns privately to the repository maintainers
- Include detailed information about the vulnerability
- Provide steps to reproduce if possible

### What to Report
- Authentication/authorization bypasses
- Credential exposure in logs or outputs
- Injection vulnerabilities in scripts
- Insecure Azure permission configurations
- Sensitive data exposure

### What We Consider Out of Scope
- Issues requiring physical access to systems
- Issues in third-party dependencies (report to respective projects)
- Issues requiring social engineering
- Issues in Azure services themselves (report to Microsoft)

## Security Best Practices

### Azure Configuration
- Use service principals with minimal required permissions
- Implement Azure RBAC for fine-grained access control
- Enable Azure AD Conditional Access when possible
- Regularly rotate service principal credentials
- Monitor Azure Activity Logs for unusual access patterns

### GitHub Repository
- Store all secrets in GitHub Secrets, never in code
- Use environment protection rules for production deployments
- Enable branch protection rules on main branch
- Regularly review and audit repository access permissions
- Enable two-factor authentication for all contributors

### Cost Data Handling
- Cost data may contain sensitive business information
- Limit access to cost reports to authorized personnel only
- Consider data retention policies for generated reports
- Use secure channels for email report distribution
- Regularly review email recipient lists

## Secure Deployment Checklist

### Before Deployment
- [ ] Service principal created with minimal permissions
- [ ] GitHub secrets configured (no sensitive data in variables)
- [ ] Email recipient lists reviewed and approved
- [ ] Budget amounts appropriate for environment
- [ ] Azure location complies with data residency requirements

### After Deployment
- [ ] Verify budget alerts are working
- [ ] Test email notifications with appropriate recipients
- [ ] Review deployed Azure resources for security compliance
- [ ] Confirm no sensitive data in generated reports
- [ ] Document access procedures for the team

### Regular Maintenance
- [ ] Rotate service principal credentials quarterly
- [ ] Review and update email recipient lists monthly
- [ ] Audit GitHub repository access permissions quarterly
- [ ] Review cost data access patterns in Azure logs
- [ ] Update dependencies and review security advisories

## Azure Permissions

The solution requires these minimal Azure permissions:

### Service Principal Permissions
- **Cost Management Reader**: Read cost and billing data
- **Contributor**: Deploy and manage infrastructure resources
- **Scope**: Subscription level (or specific resource groups)

### What These Permissions Allow
- Read cost and usage data from Azure Cost Management API
- Create and manage budgets and alerts
- Deploy Azure resources (storage, function apps, dashboards)
- Configure monitoring and logging

### What These Permissions Do NOT Allow
- Access to compute resources or data within VMs
- Modification of networking or security settings
- Access to application data or databases
- Administrative access to Azure AD

## Data Privacy

### Data Collected
- Azure resource costs and usage metrics
- Resource group and service names
- Billing and subscription information
- Budget and alert configurations

### Data Storage
- Cost data stored in Azure Log Analytics (30-day retention)
- Generated reports stored in Azure Storage (configurable retention)
- Email reports contain cost summaries (temporary)
- No personal or application data collected

### Data Access
- Cost data accessible only through Azure RBAC
- Email reports sent only to configured recipients
- GitHub Actions logs may contain deployment information (no secrets)
- Local script outputs may contain cost summaries

## Incident Response

If you suspect a security incident:

1. **Immediate Actions**
   - Revoke compromised service principal credentials
   - Review Azure Activity Logs for unauthorized access
   - Check GitHub repository for unauthorized changes
   - Disable GitHub Actions if necessary

2. **Investigation**
   - Review access logs and audit trails
   - Identify scope and impact of the incident
   - Document timeline and affected resources
   - Assess if cost data was compromised

3. **Recovery**
   - Rotate all credentials and secrets
   - Re-deploy infrastructure if necessary
   - Update security configurations
   - Notify affected stakeholders

4. **Post-Incident**
   - Conduct lessons learned review
   - Update security procedures
   - Implement additional safeguards
   - Document incident for future reference

## Contact

For security-related questions or concerns, please contact the repository maintainers through private channels rather than public issues.
