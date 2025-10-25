# Secure S3 State Bucket Policy
# Following least privilege and security best practices

# S3 bucket for Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "robert-consulting-terraform-state"
  
  tags = {
    Name        = "Terraform State Bucket"
    Purpose     = "Terraform Remote State Storage"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "Infrastructure Team"
  }
}

# Enable versioning for state durability
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption for state security
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy for cost optimization
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "state_lifecycle"
    status = "Enabled"

    # Transition old versions to IA after 30 days
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    # Delete very old versions after 1 year (keep recent versions)
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# Secure bucket policy - least privilege access
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureConnections"
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowTerraformAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/ManagedBy" = "Terraform"
          }
        }
      }
    ]
  })
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "robert-consulting-terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locks"
    Purpose     = "Terraform State Locking"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "Infrastructure Team"
  }
}

# Outputs for reference
output "terraform_state_bucket_name" {
  description = "Name of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.bucket
  sensitive   = false
}

output "terraform_state_bucket_arn" {
  description = "ARN of the Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
  sensitive   = false
}

output "terraform_locks_table_name" {
  description = "Name of the Terraform locks DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.name
  sensitive   = false
}

output "terraform_locks_table_arn" {
  description = "ARN of the Terraform locks DynamoDB table"
  value       = aws_dynamodb_table.terraform_locks.arn
  sensitive   = false
}
