#!/bin/bash

# GitHub Repository Setup Script for Azure Cost Dashboard
# This script helps you initialize the repository and set up GitHub Actions

echo "🚀 Azure Cost Dashboard - GitHub Repository Setup"
echo "================================================="

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not in a Git repository. Please run 'git init' first."
    exit 1
fi

echo "✅ Git repository detected"

# Add all files and create initial commit
echo "📦 Adding files to Git..."
git add .

# Check if there are any changes to commit
if git diff-index --quiet HEAD --; then
    echo "ℹ️ No changes to commit"
else
    echo "💬 Creating initial commit..."
    git commit -m "Initial commit: Azure Cost Dashboard

    Features:
    - Azure native cost monitoring and dashboards
    - Bicep templates for infrastructure deployment
    - GitHub Actions for automated deployment and reporting
    - Multi-environment support (dev/staging/prod)
    - Email notifications and budget alerts
    - PowerShell and Python cost reporting scripts
    
    Ready for deployment to Azure with GitHub Actions."
fi

echo ""
echo "🔧 Next Steps:"
echo "1. Create a new public repository on GitHub"
echo "2. Add the remote origin: git remote add origin https://github.com/USERNAME/REPO.git"
echo "3. Push to GitHub: git push -u origin main"
echo "4. Configure GitHub Secrets and Variables (see README.md)"
echo "5. Customize bicep.parameters.example.bicepparam"
echo "6. Push changes to trigger deployment"
echo ""
echo "📚 Documentation:"
echo "- README.md - Quick start guide"
echo "- docs/SETUP.md - Detailed setup instructions"
echo "- docs/AZURE_NATIVE_DASHBOARD.md - Dashboard features"
echo "- SECURITY.md - Security best practices"
echo ""
echo "🛡️ Security Reminders:"
echo "- Never commit real Azure credentials"
echo "- Use GitHub Secrets for sensitive values"
echo "- Review .gitignore to ensure no sensitive files are tracked"
echo "- Set up service principal with minimal required permissions"
echo ""
echo "✨ Happy cost monitoring!"
