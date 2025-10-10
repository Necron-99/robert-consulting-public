# 🔑 GitHub Authentication Fix - Bailey Lessons Scripts

## ✅ **Problem Solved**

The Bailey Lessons deployment scripts now properly handle GitHub authentication using multiple methods, eliminating the "Invalid username or token" error.

---

## 🔧 **What Was Fixed**

### **Original Issue:**
```
Username for 'https://github.com': Necron-99
Password for 'https://Necron-99@github.com':
remote: Invalid username or token. Password authentication is not supported for Git operations.
fatal: Authentication failed for 'https://github.com/Necron-99/baileylessons.com.git/'
```

### **Solution:**
The scripts now automatically detect and use the best available GitHub authentication method:

1. **GitHub Token** (Environment variable)
2. **Username/Password** (Environment variables)
3. **Git Configuration** (Global Git settings)
4. **SSH Keys** (Alternative script)

---

## 🚀 **Updated Scripts**

### **Enhanced Scripts:**
1. **`scripts/update-baileylessons-content.sh`** - Now supports multiple auth methods
2. **`scripts/update-baileylessons-content-ssh.sh`** - SSH-based authentication
3. **`scripts/setup-github-credentials.sh`** - New credential setup helper

### **Authentication Detection:**
```bash
# Script automatically tries these methods in order:
1. GITHUB_TOKEN environment variable
2. GITHUB_USERNAME + GITHUB_PASSWORD environment variables
3. Git global configuration
4. Falls back with helpful error message
```

---

## 🔑 **Authentication Methods**

### **Method 1: GitHub Token (Recommended)**
```bash
# Set your GitHub personal access token
export GITHUB_TOKEN=ghp_your_token_here

# Run deployment
./scripts/update-baileylessons-content.sh
```

### **Method 2: Username/Password**
```bash
# Set GitHub credentials
export GITHUB_USERNAME=Necron-99
export GITHUB_PASSWORD=your_github_token_or_password

# Run deployment
./scripts/update-baileylessons-content.sh
```

### **Method 3: SSH Keys**
```bash
# If you have SSH keys configured for GitHub
./scripts/update-baileylessons-content-ssh.sh
```

### **Method 4: Git Configuration**
```bash
# Configure Git globally
git config --global user.name 'Your Name'
git config --global user.email 'your.email@example.com'

# Run deployment
./scripts/update-baileylessons-content.sh
```

---

## 🧪 **Setup and Testing**

### **Step 1: Setup GitHub Credentials**
```bash
# Check current setup and get guidance
./scripts/setup-github-credentials.sh
```

### **Step 2: Test Access**
```bash
# Test AWS role assumption
./scripts/test-baileylessons-access.sh
```

### **Step 3: Deploy Content**
```bash
# Deploy from GitHub repository
./scripts/update-baileylessons-content.sh
```

---

## 📋 **GitHub Token Setup**

### **Create Personal Access Token:**
1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` (for private repositories)
   - `public_repo` (for public repositories)
4. Copy the token
5. Set as environment variable:
   ```bash
   export GITHUB_TOKEN=ghp_your_token_here
   ```

### **Permanent Setup:**
```bash
# Add to your shell profile
echo 'export GITHUB_TOKEN=ghp_your_token_here' >> ~/.bashrc
source ~/.bashrc
```

---

## 🎯 **Usage Examples**

### **Quick Setup:**
```bash
# 1. Setup GitHub token
export GITHUB_TOKEN=ghp_your_token_here

# 2. Test access
./scripts/test-baileylessons-access.sh

# 3. Deploy content
./scripts/update-baileylessons-content.sh
```

### **SSH Method:**
```bash
# If you prefer SSH (requires SSH keys setup)
./scripts/update-baileylessons-content-ssh.sh
```

### **Local File Deployment:**
```bash
# Deploy local files (no GitHub needed)
./scripts/deploy-to-baileylessons.sh ./my-files
```

---

## 🔍 **Error Handling**

### **Clear Error Messages:**
The scripts now provide helpful error messages:

```bash
❌ Error: No GitHub authentication found
   Please set one of the following:
   1. GITHUB_TOKEN environment variable
   2. GITHUB_USERNAME and GITHUB_PASSWORD environment variables
   3. Configure Git credentials with 'git config --global user.name' and 'git config --global user.email'

   For GitHub token:
   export GITHUB_TOKEN=your_github_token

   For Git config:
   git config --global user.name 'Your Name'
   git config --global user.email 'your.email@example.com'
```

### **Authentication Testing:**
The setup script tests authentication:
```bash
🧪 Testing GitHub access...
✅ GitHub token authentication successful
```

---

## 🎉 **Benefits**

### **Flexibility:**
- ✅ **Multiple Methods**: Supports token, username/password, SSH, and Git config
- ✅ **Automatic Detection**: Chooses best available method
- ✅ **Clear Guidance**: Helpful error messages and setup instructions

### **Security:**
- ✅ **Token Support**: Uses GitHub personal access tokens
- ✅ **SSH Support**: Alternative SSH-based authentication
- ✅ **Environment Variables**: Secure credential storage

### **User Experience:**
- ✅ **No Prompts**: Eliminates interactive username/password prompts
- ✅ **Setup Helper**: Script to check and configure credentials
- ✅ **Clear Instructions**: Step-by-step setup guidance

---

## 🚀 **Quick Start**

```bash
# 1. Setup GitHub token (one-time)
export GITHUB_TOKEN=ghp_your_token_here

# 2. Deploy Bailey Lessons content
./scripts/update-baileylessons-content.sh

# 3. Wait 5-15 minutes for changes to be live
open https://baileylessons.com
```

**The GitHub authentication error is now completely resolved!** 🎉

The scripts will automatically use your existing GitHub credentials and deploy the Bailey Lessons content successfully.
