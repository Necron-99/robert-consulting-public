# 🔄 Role Assumption Update - Bailey Lessons Scripts

## ✅ **Updated Scripts with Role Assumption**

I've updated the Bailey Lessons deployment scripts to automatically assume the role into the client account before updating the S3 contents.

---

## 🔧 **What's Changed**

### **Updated Scripts:**
1. **`scripts/update-baileylessons-content.sh`** - Now assumes role before deployment
2. **`scripts/deploy-to-baileylessons.sh`** - Now assumes role before deployment
3. **`scripts/test-baileylessons-access.sh`** - New script to test role assumption

### **Role Assumption Process:**
```bash
# Each script now automatically:
1. Assumes role: arn:aws:iam::[REDACTED]:role/OrganizationAccountAccessRole
2. Sets temporary credentials as environment variables
3. Verifies access to the correct account ([REDACTED])
4. Proceeds with S3 and CloudFront operations
```

---

## 🚀 **How to Use**

### **Test Access First:**
```bash
# Test role assumption and access
./scripts/test-baileylessons-access.sh
```

### **Deploy Content:**
```bash
# Update from GitHub repository
./scripts/update-baileylessons-content.sh

# Deploy local files
./scripts/deploy-to-baileylessons.sh ./my-files
```

---

## 🔐 **Security Features**

### **Role Assumption:**
- **Role ARN**: `arn:aws:iam::[REDACTED]:role/OrganizationAccountAccessRole`
- **Session Name**: Unique timestamp-based session names
- **Temporary Credentials**: Short-lived credentials for security
- **Account Verification**: Ensures correct account access

### **Access Control:**
- **S3 Bucket**: `baileylessons-production-static`
- **CloudFront**: `E23X7BS3VXFFFZ`
- **Account**: `[REDACTED]` (Bailey Lessons)

---

## 📋 **Script Details**

### **Role Assumption Code:**
```bash
# Assume role into Bailey Lessons client account
ROLE_ARN="arn:aws:iam::[REDACTED]:role/OrganizationAccountAccessRole"
SESSION_NAME="baileylessons-deployment-$(date +%s)"

# Get temporary credentials
CREDENTIALS=$(aws sts assume-role \
    --role-arn "$ROLE_ARN" \
    --role-session-name "$SESSION_NAME" \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text)

# Set environment variables
export AWS_ACCESS_KEY_ID="$ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="$SECRET_KEY"
export AWS_SESSION_TOKEN="$SESSION_TOKEN"
```

### **Verification:**
```bash
# Verify correct account
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query 'Account' --output text)
EXPECTED_ACCOUNT="[REDACTED]"
```

---

## 🧪 **Testing**

### **Test Script Features:**
- ✅ **Role Assumption**: Tests if role assumption works
- ✅ **Account Verification**: Confirms correct account access
- ✅ **S3 Access**: Tests S3 bucket access
- ✅ **CloudFront Access**: Tests CloudFront distribution access
- ✅ **Resource Listing**: Shows available resources

### **Test Output:**
```
🧪 Testing Bailey Lessons client account access...
✅ AWS CLI is configured
📋 Current AWS account: [REDACTED]
🔄 Assuming role into Bailey Lessons client account...
✅ Successfully assumed role into Bailey Lessons account ([REDACTED])
✅ S3 bucket access successful: baileylessons-production-static
✅ CloudFront distribution access successful: E23X7BS3VXFFFZ
🎉 All tests passed!
```

---

## 🎯 **Benefits**

### **Security:**
- ✅ **Proper Account Access**: Uses correct Bailey Lessons account
- ✅ **Temporary Credentials**: Short-lived access tokens
- ✅ **Role-Based Access**: Uses IAM roles for security
- ✅ **Account Isolation**: Separates client and management accounts

### **Automation:**
- ✅ **No Manual Setup**: Scripts handle role assumption automatically
- ✅ **Error Handling**: Proper error messages and validation
- ✅ **Verification**: Confirms access before proceeding
- ✅ **Cleanup**: Temporary credentials expire automatically

---

## 🔧 **Prerequisites**

### **Required Permissions:**
- **Source Account**: Permission to assume `OrganizationAccountAccessRole`
- **Target Account**: The role must exist in account `[REDACTED]`
- **AWS CLI**: Properly configured with credentials

### **Required Resources:**
- **S3 Bucket**: `baileylessons-production-static` (must exist)
- **CloudFront**: `E23X7BS3VXFFFZ` (must exist)
- **IAM Role**: `OrganizationAccountAccessRole` (must exist)

---

## 🚀 **Usage Examples**

### **Complete Workflow:**
```bash
# 1. Test access
./scripts/test-baileylessons-access.sh

# 2. Deploy from GitHub
./scripts/update-baileylessons-content.sh

# 3. Verify deployment
curl -I https://baileylessons.com
```

### **Local File Deployment:**
```bash
# 1. Make changes locally
# 2. Deploy files
./scripts/deploy-to-baileylessons.sh ./my-updated-files

# 3. Check results
open https://baileylessons.com
```

---

## 🎉 **Success Indicators**

- ✅ **Role Assumption**: Successfully assumes role into client account
- ✅ **Account Verification**: Confirms access to account [REDACTED]
- ✅ **S3 Access**: Can read/write to baileylessons-production-static
- ✅ **CloudFront Access**: Can manage distribution E23X7BS3VXFFFZ
- ✅ **Content Deployment**: Files successfully uploaded
- ✅ **Cache Invalidation**: CloudFront cache cleared

---

## 📞 **Troubleshooting**

### **Common Issues:**

**Role assumption fails:**
```bash
# Check if you have permission to assume the role
aws sts get-caller-identity

# Verify the role exists in the target account
aws iam get-role --role-name OrganizationAccountAccessRole
```

**S3 access denied:**
```bash
# Check if the bucket exists
aws s3 ls s3://baileylessons-production-static

# Verify bucket permissions
aws s3api get-bucket-location --bucket baileylessons-production-static
```

**CloudFront access denied:**
```bash
# Check distribution status
aws cloudfront get-distribution --id E23X7BS3VXFFFZ

# Verify distribution exists
aws cloudfront list-distributions --query 'DistributionList.Items[?Id==`E23X7BS3VXFFFZ`]'
```

---

## 🎯 **Summary**

**The scripts now automatically assume the role into the Bailey Lessons client account before performing any operations.** This ensures:

- ✅ **Proper Account Access**: Uses the correct AWS account
- ✅ **Security**: Temporary credentials with proper expiration
- ✅ **Automation**: No manual role assumption needed
- ✅ **Verification**: Confirms access before proceeding
- ✅ **Error Handling**: Clear error messages for troubleshooting

**Your Bailey Lessons content updates now use proper role assumption for secure, automated deployment!** 🎉
