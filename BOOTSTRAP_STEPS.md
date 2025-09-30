# Terraform S3 Backend Bootstrap - Step by Step

Follow these exact steps to set up Terraform with S3 backend storage.

## Step 1: Create S3 Bucket and DynamoDB Table

```bash
cd terraform

# Initialize Terraform (will use local state)
terraform init

# Create the S3 bucket and DynamoDB table
terraform apply -auto-approve
```

## Step 2: Enable S3 Backend

After the infrastructure is created, uncomment the backend configuration:

```bash
# Edit backend.tf and uncomment the terraform block
# Remove the # symbols from lines 3-11 in backend.tf
```

Or run this command to uncomment automatically:

```bash
# On Windows PowerShell
(Get-Content backend.tf) -replace '^# ', '' | Set-Content backend.tf
```

## Step 3: Migrate to S3 Backend

```bash
# Initialize with S3 backend (migrate state)
terraform init -migrate-state

# When prompted, choose "yes" to migrate existing state to S3
```

## Step 4: Verify Migration

```bash
# Check that state is now in S3
terraform state list

# Verify backend configuration
terraform init
```

## Step 5: Clean Up Bootstrap Files

```bash
# Move bootstrap file to backup
mv bootstrap.tf bootstrap.tf.backup

# Remove local state files (they're now in S3)
rm terraform.tfstate*
```

## Troubleshooting

If you get errors:

1. **S3 bucket doesn't exist**: Make sure Step 1 completed successfully
2. **Access denied**: Check your AWS credentials have S3 and DynamoDB permissions
3. **State migration fails**: Check the bucket name matches in both files

## Current Status

- ✅ Backend configuration is commented out (disabled)
- ✅ Bootstrap configuration is ready
- ⏳ Ready to run Step 1
