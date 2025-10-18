# Testing Bucket Manual Setup Guide

Since Terraform is not available on this system, here are the manual steps to create the properly configured testing bucket.

## Prerequisites

- AWS CLI configured with appropriate permissions
- Access to AWS Console (optional, for GUI setup)

## Manual Setup Steps

### Step 1: Create S3 Bucket

```bash
# Create the testing bucket
aws s3 mb s3://robert-consulting-testing-site --region us-east-1
```

### Step 2: Configure Public Access Block

```bash
# Configure public access block to allow public policies
aws s3api put-public-access-block --bucket robert-consulting-testing-site \
    --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
```

### Step 3: Configure Website Hosting

```bash
# Configure bucket for website hosting
aws s3 website s3://robert-consulting-testing-site --index-document index.html --error-document error.html
```

### Step 4: Set Bucket Policy

```bash
# Create bucket policy for public read access
cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::robert-consulting-testing-site/*"
        }
    ]
}
EOF

# Apply the bucket policy
aws s3api put-bucket-policy --bucket robert-consulting-testing-site --policy file://bucket-policy.json

# Clean up
rm bucket-policy.json
```

### Step 5: Verify Configuration

```bash
# Verify public access block configuration
aws s3api get-public-access-block --bucket robert-consulting-testing-site

# Verify bucket policy
aws s3api get-bucket-policy --bucket robert-consulting-testing-site

# Verify website configuration
aws s3api get-bucket-website --bucket robert-consulting-testing-site
```

## Expected Output

### Public Access Block Configuration:
```json
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": false,
        "IgnorePublicAcls": false,
        "BlockPublicPolicy": false,
        "RestrictPublicBuckets": false
    }
}
```

### Bucket Policy:
```json
{
    "Policy": "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"PublicReadGetObject\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":\"s3:GetObject\",\"Resource\":\"arn:aws:s3:::robert-consulting-testing-site/*\"}]}"
}
```

## Testing the Setup

### Step 1: Upload Test Files

```bash
# Create a simple test file
echo "<html><body><h1>Testing Site</h1><p>This is a test.</p></body></html>" > test.html

# Upload to the bucket
aws s3 cp test.html s3://robert-consulting-testing-site/

# Clean up
rm test.html
```

### Step 2: Test Access

```bash
# Test the website URL
curl http://robert-consulting-testing-site.s3-website-us-east-1.amazonaws.com/test.html
```

## GitHub Actions Integration

Once the bucket is properly configured, the GitHub Actions workflow will:

1. ✅ **Verify bucket exists**: Check that `robert-consulting-testing-site` is accessible
2. ✅ **Sync files**: Upload testing files without permission issues
3. ✅ **Deploy successfully**: Complete the testing site deployment

## Troubleshooting

### If you get "AccessDenied" errors:

1. **Check IAM permissions**: Ensure your AWS user has `s3:PutPublicAccessBlock` permission
2. **Verify bucket ownership**: Make sure you own the bucket
3. **Check region**: Ensure you're using the correct AWS region

### If the bucket policy fails:

1. **Verify public access block**: Run `aws s3api get-public-access-block --bucket robert-consulting-testing-site`
2. **Check permissions**: Ensure you have `s3:PutBucketPolicy` permission
3. **Try manual setup**: Use the AWS Console to configure the bucket manually

## Next Steps

After completing this setup:

1. **Test GitHub Actions**: Push a change to trigger the testing deployment
2. **Verify deployment**: Check that files are uploaded successfully
3. **Access testing site**: Visit the S3 website URL to confirm it works

## Benefits of This Approach

- ✅ **No random buckets**: Uses a single, fixed bucket name
- ✅ **Proper permissions**: Configured with correct public access settings
- ✅ **No IAM issues**: GitHub Actions can deploy without permission problems
- ✅ **Consistent**: Same bucket used for all testing deployments
- ✅ **Cost effective**: Single bucket instead of multiple random buckets
