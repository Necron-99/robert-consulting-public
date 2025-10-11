#!/bin/bash

# Setup GitHub Environment for Production Deployment
# This script helps configure the GitHub environment for manual approval

echo "🔧 Setting up GitHub Environment for Production Deployment"
echo "=========================================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo ""
    echo "📋 Manual Setup Required"
    echo "========================"
    echo "Since GitHub CLI is not available, please follow the manual setup guide:"
    echo ""
    echo "📖 See: MANUAL_GITHUB_ENVIRONMENT_SETUP.md"
    echo ""
    echo "🔗 Quick Setup Steps:"
    echo "1. Go to: https://github.com/Necron-99/robert-consulting.net/settings/environments"
    echo "2. Click 'New environment'"
    echo "3. Name it: production-deployment"
    echo "4. Add protection rules for required reviewers"
    echo "5. Save the configuration"
    echo ""
    echo "📥 To install GitHub CLI later:"
    echo "   macOS: brew install gh"
    echo "   Linux: See https://cli.github.com/"
    echo "   Windows: See https://cli.github.com/"
    echo ""
    exit 0
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

# Get current user ID
USER_ID=$(gh api user --jq .id)
echo "👤 Current user ID: $USER_ID"

# Create environment with protection rules
gh api repos/$REPO/environments/production-deployment \
  --method PUT \
  --input - << EOF
{
  "protection_rules": [
    {
      "type": "required_reviewers",
      "reviewers": [
        {
          "type": "User",
          "id": $USER_ID
        }
      ]
    }
  ],
  "deployment_branch_policy": {
    "protected_branches": true,
    "custom_branch_policies": false
  }
}
EOF

if [ $? -eq 0 ]; then
    echo "✅ Production deployment environment created successfully"
else
    echo "⚠️ Environment may already exist or there was an issue"
    echo "🔍 Checking existing environments..."
    ENVIRONMENTS=$(gh api repos/$REPO/environments --jq '.[].name' 2>/dev/null)
    if echo "$ENVIRONMENTS" | grep -q "production-deployment"; then
        echo "✅ Environment already exists"
    else
        echo "❌ Failed to create environment"
        echo "🔧 You can create it manually in GitHub:"
        echo "   1. Go to Settings → Environments"
        echo "   2. Click 'New environment'"
        echo "   3. Name it 'production-deployment'"
        echo "   4. Add protection rules for required reviewers"
        exit 1
    fi
fi

# Display environment information
echo ""
echo "📋 Environment Configuration:"
echo "============================="
ENV_INFO=$(gh api repos/$REPO/environments/production-deployment 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "$ENV_INFO" | jq '{
        name: .name,
        protection_rules: .protection_rules | length,
        deployment_branch_policy: .deployment_branch_policy
    }'
else
    echo "⚠️ Could not retrieve environment details"
    echo "🔍 Environment may need to be created manually"
fi

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
