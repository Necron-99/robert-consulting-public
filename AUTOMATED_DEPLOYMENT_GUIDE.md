# Automated CloudFront Cache Invalidation Guide

## 🚀 Overview

This guide shows you how to automate CloudFront cache invalidation every time you make changes to your website. No more manual cache clearing!

## 📋 Available Solutions

### 1. **GitHub Actions (Recommended)**
Automatically invalidates cache on every push to main branch.

### 2. **Shell Script**
Manual deployment with automatic cache invalidation.

### 3. **Node.js Script**
Programmatic cache invalidation with status checking.

## 🔧 Setup Instructions

### Option 1: GitHub Actions (Fully Automated)

#### 1. **Configure GitHub Secrets**
Go to your repository → Settings → Secrets and variables → Actions

Add these secrets:
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

#### 2. **Enable GitHub Actions**
The workflow file is already created at `.github/workflows/deploy.yml`

#### 3. **How It Works**
- **Automatic**: Every push to `main` branch triggers deployment
- **Manual**: Go to Actions tab → "Deploy Website with Cache Invalidation" → Run workflow
- **Options**: Choose to wait for invalidation completion

#### 4. **Usage**
```bash
# Just push to main branch
git add .
git commit -m "Update website"
git push origin main
# Cache invalidation happens automatically!
```

### Option 2: Shell Script (Semi-Automated)

#### 1. **Make Script Executable**
```bash
chmod +x website/deploy-with-invalidation.sh
```

#### 2. **Run Deployment**
```bash
# Quick deployment (don't wait for completion)
./website/deploy-with-invalidation.sh

# Wait for invalidation to complete
./website/deploy-with-invalidation.sh --wait
```

#### 3. **Features**
- ✅ Deploys files to S3
- ✅ Automatically invalidates CloudFront cache
- ✅ Shows deployment summary
- ✅ Optional: Wait for invalidation completion
- ✅ Colored output for better visibility

### Option 3: Node.js Script (Programmatic)

#### 1. **Install Dependencies**
```bash
cd website
npm install
```

#### 2. **Available Commands**
```bash
# Invalidate all files
npm run invalidate

# Invalidate specific files
npm run deploy:files index.html learning.html

# Check invalidation status
npm run status I1ODCEPB8MEPURGPH0W0I2EFYO

# Deploy and invalidate
npm run deploy
```

#### 3. **Programmatic Usage**
```javascript
const CloudFrontInvalidator = require('./auto-invalidate.js');

const invalidator = new CloudFrontInvalidator();

// Invalidate all files
await invalidator.invalidateAll();

// Invalidate specific files
await invalidator.invalidateFiles(['index.html', 'learning.html']);

// Check status
const status = await invalidator.checkInvalidationStatus('INVALIDATION_ID');
```

## 🎯 Recommended Approach

### **For Production: GitHub Actions**
- ✅ Fully automated
- ✅ No manual intervention
- ✅ Runs on every push
- ✅ Professional CI/CD pipeline

### **For Development: Shell Script**
- ✅ Quick manual deployment
- ✅ Immediate feedback
- ✅ Easy to customize
- ✅ Good for testing

### **For Advanced Users: Node.js Script**
- ✅ Programmatic control
- ✅ Custom logic
- ✅ Integration with other tools
- ✅ Status monitoring

## 📊 Monitoring & Status

### **Check Invalidation Status**
```bash
# Using AWS CLI
aws cloudfront get-invalidation --distribution-id E3HUVB85SPZFHO --id INVALIDATION_ID

# Using Node.js script
npm run status INVALIDATION_ID
```

### **Common Status Values**
- `InProgress`: Cache invalidation is running
- `Completed`: Cache invalidation finished
- `Failed`: Invalidation failed (rare)

## ⚡ Performance Tips

### **Selective Invalidation**
Instead of invalidating all files (`/*`), you can invalidate specific files:

```bash
# Invalidate only changed files
npm run deploy:files index.html learning.html styles.css

# In shell script
aws cloudfront create-invalidation \
  --distribution-id E3HUVB85SPZFHO \
  --paths "/index.html" "/learning.html" "/styles.css"
```

### **Cost Optimization**
- **Full Invalidation**: `/*` (more expensive, but ensures all changes are visible)
- **Selective Invalidation**: Specific files (cheaper, but requires knowing which files changed)

## 🔍 Troubleshooting

### **Changes Not Visible**
1. **Wait 5-15 minutes** - CloudFront propagation takes time
2. **Force refresh** - Ctrl+F5 or Cmd+Shift+R
3. **Try incognito mode** - Bypass browser cache
4. **Check invalidation status** - Ensure it completed successfully

### **Invalidation Failed**
1. **Check AWS credentials** - Ensure they have CloudFront permissions
2. **Verify distribution ID** - Make sure it's correct
3. **Check AWS region** - Ensure you're in the right region

### **Script Errors**
1. **Install dependencies** - `npm install` for Node.js scripts
2. **Check permissions** - Make sure scripts are executable
3. **Verify AWS CLI** - `aws sts get-caller-identity`

## 📈 Benefits

### **Before (Manual)**
- ❌ Manual cache invalidation every time
- ❌ Easy to forget
- ❌ Time-consuming
- ❌ Error-prone

### **After (Automated)**
- ✅ Automatic cache invalidation
- ✅ Never forget to invalidate
- ✅ Saves time
- ✅ Reliable and consistent
- ✅ Professional deployment process

## 🎉 Next Steps

1. **Choose your preferred method** (GitHub Actions recommended)
2. **Set up the automation** following the instructions above
3. **Test the deployment** to ensure it works
4. **Enjoy automated deployments!** 🚀

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Verify your AWS credentials and permissions
3. Ensure all dependencies are installed
4. Check the CloudFront distribution status in AWS Console

**Happy deploying!** 🎯
