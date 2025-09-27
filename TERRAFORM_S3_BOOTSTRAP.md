# Terraform S3 Backend Bootstrap Guide

This guide will help you create the S3 bucket and DynamoDB table needed for Terraform state storage.

## The Problem

You can't use an S3 backend until the S3 bucket exists, but you can't create the S3 bucket with Terraform if your state is stored in S3. This is a classic chicken-and-egg problem.

## Solution: Bootstrap Process

We'll use a bootstrap approach to create the infrastructure first, then migrate to S3 backend.

## Step 1: Create Bootstrap Infrastructure

First, let's create the S3 bucket and DynamoDB table using local state:

```bash
cd terraform

# Initialize Terraform (this will use local state initially)
terraform init

# Apply the bootstrap configuration to create S3 bucket and DynamoDB table
terraform apply -auto-approve
```

## Step 2: Verify Infrastructure Creation

Check that the resources were created:

```bash
# List the created resources
terraform output

# Verify S3 bucket exists
aws s3 ls s3://robert-consulting-terraform-state

# Verify DynamoDB table exists
aws dynamodb describe-table --table-name terraform-state-lock
```

## Step 3: Configure S3 Backend

Now that the infrastructure exists, configure the S3 backend:

```bash
# Initialize with S3 backend (this will migrate your state)
terraform init -migrate-state

# When prompted, choose "yes" to migrate existing state to S3
```

## Step 4: Clean Up Bootstrap Files

After successful migration, you can clean up:

```bash
# Move bootstrap files to backup
mv bootstrap.tf bootstrap.tf.backup
mv bootstrap.sh bootstrap.sh.backup

# Remove local state files (they're now in S3)
rm terraform.tfstate*
```

## Alternative: Manual Creation

If you prefer to create the resources manually:

### Create S3 Bucket

```bash
aws s3 mb s3://robert-consulting-terraform-state --region us-east-1
aws s3api put-bucket-versioning --bucket robert-consulting-terraform-state --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket robert-consulting-terraform-state --server-side-encryption-configuration '{
  "Rules": [
    {
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }
  ]
}'
aws s3api put-public-access-block --bucket robert-consulting-terraform-state --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### Create DynamoDB Table

```bash
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## Troubleshooting

### Common Issues

1. **Bucket Already Exists**: If the bucket name is taken, modify the bucket name in `bootstrap.tf` and `backend.tf`

2. **Access Denied**: Ensure your AWS credentials have the necessary permissions:
   - S3: `s3:CreateBucket`, `s3:PutBucketVersioning`, `s3:PutBucketEncryption`, `s3:PutPublicAccessBlock`
   - DynamoDB: `dynamodb:CreateTable`

3. **State Migration Fails**: If state migration fails:
   ```bash
   # Backup your state
   cp terraform.tfstate terraform.tfstate.backup
   
   # Try migration again
   terraform init -migrate-state
   ```

## Verification

After successful setup, verify everything works:

```bash
# Check backend configuration
terraform init

# List resources in state
terraform state list

# Plan should work without errors
terraform plan
```

## Security Notes

- The S3 bucket has encryption enabled
- Public access is blocked
- Versioning is enabled for state history
- DynamoDB table provides state locking

Your Terraform state is now securely stored in S3! 🎉
