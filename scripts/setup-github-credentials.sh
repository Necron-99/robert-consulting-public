#!/bin/bash
# Setup GitHub credentials for Bailey Lessons deployment

echo "🔑 Setting up GitHub credentials for Bailey Lessons deployment..."

# Check current Git configuration
echo "📋 Current Git configuration:"
echo "   User name: $(git config --global user.name 2>/dev/null || echo 'Not set')"
echo "   User email: $(git config --global user.email 2>/dev/null || echo 'Not set')"

# Check for existing GitHub token
if [ -n "$GITHUB_TOKEN" ]; then
    echo "✅ GITHUB_TOKEN environment variable is set"
else
    echo "❌ GITHUB_TOKEN environment variable is not set"
fi

# Check for GitHub username/password
if [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_PASSWORD" ]; then
    echo "✅ GITHUB_USERNAME and GITHUB_PASSWORD environment variables are set"
else
    echo "❌ GITHUB_USERNAME and GITHUB_PASSWORD environment variables are not set"
fi

echo ""
echo "🔧 GitHub Authentication Options:"
echo ""
echo "Option 1: Set GitHub Token (Recommended)"
echo "   export GITHUB_TOKEN=your_github_personal_access_token"
echo ""
echo "Option 2: Set GitHub Username/Password"
echo "   export GITHUB_USERNAME=your_github_username"
echo "   export GITHUB_PASSWORD=your_github_token_or_password"
echo ""
echo "Option 3: Configure Git globally"
echo "   git config --global user.name 'Your Name'"
echo "   git config --global user.email 'your.email@example.com'"
echo "   git config --global credential.helper store"
echo ""

# Test GitHub access
echo "🧪 Testing GitHub access..."

if [ -n "$GITHUB_TOKEN" ]; then
    echo "Testing with GITHUB_TOKEN..."
    if curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user > /dev/null; then
        echo "✅ GitHub token authentication successful"
    else
        echo "❌ GitHub token authentication failed"
    fi
elif [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_PASSWORD" ]; then
    echo "Testing with GITHUB_USERNAME and GITHUB_PASSWORD..."
    if curl -s -u "$GITHUB_USERNAME:$GITHUB_PASSWORD" https://api.github.com/user > /dev/null; then
        echo "✅ GitHub username/password authentication successful"
    else
        echo "❌ GitHub username/password authentication failed"
    fi
else
    echo "⚠️  No GitHub credentials found for testing"
fi

echo ""
echo "📋 To create a GitHub Personal Access Token:"
echo "   1. Go to https://github.com/settings/tokens"
echo "   2. Click 'Generate new token'"
echo "   3. Select scopes: 'repo' (for private repos) or 'public_repo' (for public repos)"
echo "   4. Copy the token and set it as GITHUB_TOKEN"
echo ""
echo "💡 For permanent setup, add to your ~/.bashrc or ~/.zshrc:"
echo "   echo 'export GITHUB_TOKEN=your_token_here' >> ~/.bashrc"
echo "   source ~/.bashrc"
