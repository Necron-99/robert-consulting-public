# Terraform State Migration to S3

This guide explains how to migrate your existing Terraform state to S3 backend storage.

## Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform installed
3. Existing Terraform state files (if any)

## Step 1: Create S3 Backend Infrastructure

First, you need to create the S3 bucket and DynamoDB table for state storage:

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Plan the S3 backend infrastructure
terraform plan -target=aws_s3_bucket.terraform_state
terraform plan -target=aws_dynamodb_table.terraform_state_lock

# Apply the S3 backend infrastructure
terraform apply -target=aws_s3_bucket.terraform_state
terraform apply -target=aws_dynamodb_table.terraform_state_lock
```

## Step 2: Migrate Existing State (if applicable)

If you have existing state files, you need to migrate them to S3:

```bash
# Backup existing state
cp terraform.tfstate terraform.tfstate.backup

# Initialize with S3 backend
terraform init

# When prompted, choose "yes" to migrate existing state to S3
# Terraform will ask: "Do you want to copy existing state to the new backend?"
# Answer: yes
```

## Step 3: Verify State Migration

Verify that your state has been successfully migrated:

```bash
# Check state location
terraform state list

# Verify backend configuration
terraform init
```

## Step 4: Clean Up Local State Files

After successful migration, you can remove local state files:

```bash
# Remove local state files (they're now in S3)
rm terraform.tfstate*
```

## Backend Configuration Details

The S3 backend is configured with:

- **Bucket**: `robert-consulting-terraform-state`
- **Key**: `terraform.tfstate`
- **Region**: `us-east-1`
- **Encryption**: Enabled (AES256)
- **Versioning**: Enabled
- **Locking**: DynamoDB table `terraform-state-lock`

## Security Features

- ✅ Server-side encryption enabled
- ✅ Public access blocked
- ✅ Versioning enabled for state history
- ✅ DynamoDB table for state locking
- ✅ Proper IAM permissions required

## Troubleshooting

### Common Issues

1. **Access Denied**: Ensure your AWS credentials have the necessary permissions:
   - `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on the state bucket
   - `dynamodb:GetItem`, `dynamodb:PutItem`, `dynamodb:DeleteItem` on the lock table

2. **Bucket Already Exists**: If the bucket name is taken, modify the bucket name in `backend.tf` and `s3-backend.tf`

3. **State Lock Issues**: If you encounter state lock issues:
   ```bash
   terraform force-unlock <LOCK_ID>
   ```

### Useful Commands

```bash
# Check current backend configuration
terraform init

# List all resources in state
terraform state list

# Show specific resource
terraform state show <resource_name>

# Import existing resource to state
terraform import <resource_type>.<resource_name> <resource_id>
```

## Next Steps

After successful migration:

1. Update your CI/CD pipelines to use the S3 backend
2. Ensure all team members have access to the S3 bucket
3. Consider setting up state file backups
4. Document the backend configuration for your team

## Rollback Plan

If you need to rollback to local state:

1. Copy the backup state file: `cp terraform.tfstate.backup terraform.tfstate`
2. Remove or comment out the backend configuration in `backend.tf`
3. Run `terraform init` to reconfigure for local state
