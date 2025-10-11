#!/bin/bash

# Setup GitHub Environment for Production Deployment
# This script helps configure the GitHub environment for manual approval

echo "🔧 Setting up GitHub Environment for Production Deployment"
echo "=========================================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "📥 Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI"
    echo "🔐 Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"

# Get repository information
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "📁 Repository: $REPO"

# Create the production-deployment environment
echo "🏗️ Creating production-deployment environment..."

# Create environment with protection rules
gh api repos/$REPO/environments/production-deployment \
  --method PUT \
  --field name=production-deployment \
  --field protection_rules='[{"type":"required_reviewers","reviewers":[{"type":"User","id":'$(gh api user --jq .id)'}]}]' \
  --field reviewers='[{"type":"User","id":'$(gh api user --jq .id)'}]' \
  --field deployment_branch_policy='{"protected_branches":true,"custom_branch_policies":false}' \
  --field environment_url="https://robertconsulting.net" \
  --field description="Production deployment environment with manual approval required"

if [ $? -eq 0 ]; then
    echo "✅ Production deployment environment created successfully"
else
    echo "⚠️ Environment may already exist or there was an issue"
    echo "🔍 Checking existing environments..."
    gh api repos/$REPO/environments --jq '.[].name' | grep -q "production-deployment"
    if [ $? -eq 0 ]; then
        echo "✅ Environment already exists"
    else
        echo "❌ Failed to create environment"
        exit 1
    fi
fi

# Display environment information
echo ""
echo "📋 Environment Configuration:"
echo "============================="
gh api repos/$REPO/environments/production-deployment --jq '{
    name: .name,
    url: .environment_url,
    protection_rules: .protection_rules | length,
    reviewers: .reviewers | length
}'

echo ""
echo "🎉 GitHub Environment Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Test the deployment pipeline by making a commit to main"
echo "2. Review the staging deployment at: https://staging.robertconsulting.net"
echo "3. Approve the production deployment when ready"
echo "4. Monitor the deployment process"
echo ""
echo "🔗 Useful Links:"
echo "- Staging Environment: https://staging.robertconsulting.net"
echo "- Production Environment: https://robertconsulting.net"
echo "- GitHub Actions: https://github.com/$REPO/actions"
echo ""
echo "⚠️ Important Notes:"
echo "- Manual approval is required for all production deployments"
echo "- Emergency deployments can bypass this process (use with caution)"
echo "- All deployments are logged and auditable"
echo "- Staging environment is IP-restricted for security"
