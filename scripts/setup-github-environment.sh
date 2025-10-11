#!/bin/bash

# Setup GitHub Environment for Production Deployment
# This script helps configure the GitHub environment for manual approval

echo "🔧 Setting up GitHub Environment for Production Deployment"
echo "=========================================================="

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo ""
    echo "📋 Manual Setup Required (2025 Instructions)"
    echo "============================================="
    echo "Since GitHub CLI is not available, please follow the manual setup guide:"
    echo ""
    echo "📖 See: MANUAL_GITHUB_ENVIRONMENT_SETUP.md"
    echo ""
    echo "🔗 Quick Setup Steps (2025 Interface):"
    echo "1. Go to: https://github.com/Necron-99/robert-consulting.net/settings/environments"
    echo "2. Click 'New environment' (green button in top right)"
    echo "3. Name it: production-deployment"
    echo "4. In 'Deployment protection rules' section:"
    echo "   - Check 'Required reviewers'"
    echo "   - Click 'Add people or teams'"
    echo "   - Search for and select 'Necron-99'"
    echo "   - Set required reviewers to 1"
    echo "5. Click 'Save protection rules'"
    echo ""
    echo "🔄 Alternative: Use Fallback Workflow (No Setup Required)"
    echo "1. Go to Actions tab"
    echo "2. Click 'Staging to Production Deployment Pipeline (Fallback)'"
    echo "3. Click 'Run workflow'"
    echo "4. Comment 'APPROVE' on the created GitHub issue"
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
    echo ""
    echo "🔐 Authentication Required"
    echo "========================="
    echo "To use GitHub CLI, you need to authenticate first:"
    echo ""
    echo "1. Run: gh auth login"
    echo "2. Follow the prompts to authenticate"
    echo "3. Choose your preferred authentication method"
    echo ""
    echo "🔄 Alternative: Use Manual Setup (No CLI Required)"
    echo "Since authentication is required, you can use the manual setup instead:"
    echo ""
    echo "📖 See: MANUAL_GITHUB_ENVIRONMENT_SETUP.md"
    echo ""
    echo "🔗 Quick Manual Setup Steps:"
    echo "1. Go to: https://github.com/Necron-99/robert-consulting.net/settings/environments"
    echo "2. Click 'New environment' (green button in top right)"
    echo "3. Name it: production-deployment"
    echo "4. In 'Deployment protection rules' section:"
    echo "   - Check 'Required reviewers'"
    echo "   - Click 'Add people or teams'"
    echo "   - Search for and select 'Necron-99'"
    echo "   - Set required reviewers to 1"
    echo "5. Click 'Save protection rules'"
    echo ""
    echo "🔄 Or Use Fallback Workflow (No Setup Required):"
    echo "1. Go to Actions tab"
    echo "2. Click 'Staging to Production Deployment Pipeline (Fallback)'"
    echo "3. Click 'Run workflow'"
    echo "4. Comment 'APPROVE' on the created GitHub issue"
    echo ""
    exit 0
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

# Create basic environment (protection rules must be added manually)
echo "🏗️ Creating basic environment (protection rules require manual setup)..."

# Create a basic environment first
gh api repos/$REPO/environments/production-deployment \
  --method PUT \
  --input - << EOF
{
  "deployment_branch_policy": {
    "protected_branches": true,
    "custom_branch_policies": false
  }
}
EOF

# Note: Protection rules cannot be set via API in most cases
echo "ℹ️ Note: Protection rules must be configured manually in GitHub UI"

if [ $? -eq 0 ]; then
    echo "✅ Production deployment environment created successfully"
    echo ""
    echo "🔧 Next Step: Configure Protection Rules Manually"
    echo "=================================================="
    echo "The environment was created, but protection rules must be added manually:"
    echo ""
    echo "1. Go to: https://github.com/$REPO/settings/environments"
    echo "2. Click on 'production-deployment' environment"
    echo "3. In 'Deployment protection rules' section:"
    echo "   - Check 'Required reviewers'"
    echo "   - Click 'Add people or teams'"
    echo "   - Search for and select your username"
    echo "   - Set required reviewers to 1"
    echo "4. Click 'Save protection rules'"
    echo ""
else
    echo "⚠️ Environment may already exist or there was an issue"
    echo "🔍 Checking existing environments..."
    ENVIRONMENTS=$(gh api repos/$REPO/environments --jq '.[].name' 2>/dev/null)
    if echo "$ENVIRONMENTS" | grep -q "production-deployment"; then
        echo "✅ Environment already exists"
    else
        echo "❌ Failed to create environment via CLI"
        echo ""
        echo "🔧 Manual Setup Required (2025 Interface):"
        echo "==========================================="
        echo "1. Go to: https://github.com/$REPO/settings/environments"
        echo "2. Click 'New environment' (green button in top right)"
        echo "3. Name it: production-deployment"
        echo "4. In 'Deployment protection rules' section:"
        echo "   - Check 'Required reviewers'"
        echo "   - Click 'Add people or teams'"
        echo "   - Search for and select your username"
        echo "   - Set required reviewers to 1"
        echo "5. Click 'Save protection rules'"
        echo ""
        echo "🔄 Alternative: Use Fallback Workflow (No Setup Required)"
        echo "1. Go to Actions tab"
        echo "2. Click 'Staging to Production Deployment Pipeline (Fallback)'"
        echo "3. Click 'Run workflow'"
        echo "4. Comment 'APPROVE' on the created GitHub issue"
        echo ""
        echo "📖 See: MANUAL_GITHUB_ENVIRONMENT_SETUP.md for detailed instructions"
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
echo "- Environment Settings: https://github.com/$REPO/settings/environments"
echo ""
echo "🔄 Alternative Workflows:"
echo "- Main Workflow: 'Staging to Production Deployment Pipeline'"
echo "- Fallback Workflow: 'Staging to Production Deployment Pipeline (Fallback)'"
echo "- Emergency Workflow: 'Legacy Direct Deployment (Deprecated)'"
echo ""
echo "⚠️ Important Notes:"
echo "- Manual approval is required for all production deployments"
echo "- Emergency deployments can bypass this process (use with caution)"
echo "- All deployments are logged and auditable"
echo "- Staging environment is IP-restricted for security"
echo "- Fallback workflow uses GitHub issues for approval (no environment needed)"
