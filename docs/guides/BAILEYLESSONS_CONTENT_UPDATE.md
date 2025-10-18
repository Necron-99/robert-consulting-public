# 🎓 Bailey Lessons Content Update Guide

## 🎯 **Simple Content Deployment**

This guide shows you how to update the content for `baileylessons.com` by deploying to the existing S3 bucket and creating a CloudFront invalidation.

---

## 🚀 **Quick Update from GitHub Repository**

### **Option 1: Update from GitHub Repository**
```bash
# Deploy latest content from the baileylessons.com repository
./scripts/update-baileylessons-content.sh
```

This script will:
1. **Assume Role** into Bailey Lessons client account ([REDACTED])
2. Clone the `Necron-99/baileylessons.com` repository
3. Deploy content to the existing S3 bucket (`baileylessons-production-static`)
4. Create a CloudFront invalidation for distribution `E23X7BS3VXFFFZ`
5. Clean up temporary files

---

## 📁 **Manual File Deployment**

### **Option 2: Deploy Local Files**
```bash
# Deploy files from current directory
./scripts/deploy-to-baileylessons.sh

# Deploy files from specific directory
./scripts/deploy-to-baileylessons.sh ./my-website-files
```

This script will:
1. **Assume Role** into Bailey Lessons client account ([REDACTED])
2. Deploy local files to the S3 bucket
3. Set appropriate cache headers
4. Create CloudFront invalidation

---

## 🔑 **GitHub Authentication Methods**

### **Method 1: GitHub Token (Recommended)**
```bash
# Set GitHub token
export GITHUB_TOKEN=your_github_personal_access_token

# Run deployment
./scripts/update-baileylessons-content.sh
```

### **Method 2: GitHub Username/Password**
```bash
# Set GitHub credentials
export GITHUB_USERNAME=your_github_username
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
git config --global credential.helper store

# Run deployment
./scripts/update-baileylessons-content.sh
```

---

## 🔧 **Manual AWS Commands**

### **Direct S3 Deployment:**
```bash
# Deploy to S3 bucket
aws s3 sync ./your-content/ s3://baileylessons-production-static/ --delete

# Create CloudFront invalidation
aws cloudfront create-invalidation \
  --distribution-id E23X7BS3VXFFFZ \
  --paths "/*"
```

---

## 📋 **Configuration Details**

### **AWS Resources:**
- **S3 Bucket**: `baileylessons-production-static`
- **CloudFront Distribution**: `E23X7BS3VXFFFZ`
- **Domain**: `baileylessons.com`
- **AWS Account**: `[REDACTED]`

### **Repository:**
- **GitHub**: `Necron-99/baileylessons.com`
- **Content Location**: `content/website/` directory
- **Content**: Website files (HTML, CSS, JS, images, etc.)

**Note**: The website content is located in `content/website/` rather than the root directory.

---

## 🧪 **Test Access First**

### **Test Role Assumption:**
```bash
# Test access to Bailey Lessons account
./scripts/test-baileylessons-access.sh
```

This will verify:
- ✅ Role assumption works
- ✅ S3 bucket access
- ✅ CloudFront access

### **Setup GitHub Credentials:**
```bash
# Check and setup GitHub authentication
./scripts/setup-github-credentials.sh
```

This will help you configure:
- ✅ GitHub token authentication
- ✅ Username/password authentication
- ✅ Git credential configuration

---

## 🎯 **Usage Examples**

### **Update from GitHub:**
```bash
# 1. Setup GitHub credentials (if needed)
./scripts/setup-github-credentials.sh

# 2. Test access first (optional)
./scripts/test-baileylessons-access.sh

# 3. Run the update script (HTTPS with token)
./scripts/update-baileylessons-content.sh

# OR use SSH method (if SSH keys are configured)
./scripts/update-baileylessons-content-ssh.sh

# 4. Follow the prompts
# 5. Wait 5-15 minutes for changes to be live
```

### **Deploy Local Changes:**
```bash
# 1. Make your changes locally
# 2. Run the deploy script
./scripts/deploy-to-baileylessons.sh ./my-updated-files

# 3. Wait for CloudFront invalidation
```

### **Quick File Update:**
```bash
# Update a single file
aws s3 cp ./index.html s3://baileylessons-production-static/

# Invalidate specific path
aws cloudfront create-invalidation \
  --distribution-id E23X7BS3VXFFFZ \
  --paths "/index.html"
```

---

## ⚡ **Cache Headers**

The scripts automatically set appropriate cache headers:

- **Static Assets** (images, fonts, etc.): `max-age=31536000` (1 year)
- **HTML/CSS/JS**: `max-age=3600` (1 hour)

This ensures:
- Fast loading for static assets
- Reasonable cache for dynamic content
- Easy updates when needed

---

## 🔍 **Verification**

### **Check Deployment:**
```bash
# List S3 bucket contents
aws s3 ls s3://baileylessons-production-static/

# Check CloudFront distribution status
aws cloudfront get-distribution --id E23X7BS3VXFFFZ

# Monitor invalidation progress
aws cloudfront get-invalidation \
  --distribution-id E23X7BS3VXFFFZ \
  --id <invalidation-id>
```

### **Test Website:**
- Visit: `https://baileylessons.com`
- Check: Content updates are visible
- Verify: All assets load correctly

---

## 🛠️ **Troubleshooting**

### **Common Issues:**

**AWS CLI not configured:**
```bash
aws configure
# Enter your AWS credentials for account [REDACTED]
```

**S3 bucket access denied:**
```bash
# Check your AWS credentials
aws sts get-caller-identity

# Verify you're using the correct account ([REDACTED])
```

**CloudFront invalidation failed:**
```bash
# Check distribution status
aws cloudfront get-distribution --id E23X7BS3VXFFFZ

# Verify distribution is deployed
```

**Content not updating:**
```bash
# Check cache headers
aws s3api head-object --bucket baileylessons-production-static --key index.html

# Force invalidation
aws cloudfront create-invalidation \
  --distribution-id E23X7BS3VXFFFZ \
  --paths "/*"
```

---

## 📊 **Deployment Process**

1. **Source**: GitHub repository or local files
2. **Upload**: Files synced to S3 bucket
3. **Cache**: Appropriate headers set
4. **Invalidation**: CloudFront cache cleared
5. **Live**: Changes visible in 5-15 minutes

---

## 🎉 **Success Indicators**

- ✅ **S3 Upload**: Files successfully uploaded
- ✅ **CloudFront Invalidation**: Invalidation created
- ✅ **Website Update**: Changes visible at baileylessons.com
- ✅ **Performance**: Fast loading with proper caching

---

## 💡 **Best Practices**

1. **Test Locally**: Verify changes work before deploying
2. **Use Version Control**: Keep track of changes in Git
3. **Monitor Deployment**: Check invalidation status
4. **Verify Results**: Test the live website after deployment
5. **Backup**: Keep backups of working versions

---

## 🚀 **Quick Commands Summary**

```bash
# Setup GitHub credentials
./scripts/setup-github-credentials.sh

# Test access to Bailey Lessons account
./scripts/test-baileylessons-access.sh

# Update from GitHub repository (HTTPS with token)
./scripts/update-baileylessons-content.sh

# Update from GitHub repository (SSH method)
./scripts/update-baileylessons-content-ssh.sh

# Deploy local files
./scripts/deploy-to-baileylessons.sh

# Manual role assumption + S3 sync
aws sts assume-role --role-arn arn:aws:iam::[REDACTED]:role/OrganizationAccountAccessRole --role-session-name deployment
aws s3 sync ./ s3://baileylessons-production-static/ --delete

# Manual invalidation
aws cloudfront create-invalidation --distribution-id E23X7BS3VXFFFZ --paths "/*"
```

**That's it! Simple content updates for baileylessons.com using the existing infrastructure.** 🎉
