# Security Configuration and Best Practices

# Data source for current AWS account
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# KMS key for encryption
resource "aws_kms_key" "security_key" {
  description             = "Security key for ${var.environment} environment"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(local.common_security_tags, {
    Name = "${var.environment}-security-key"
    Purpose = "Encryption"
  })
}

resource "aws_kms_alias" "security_key" {
  name          = "alias/${var.environment}-security-key"
  target_key_id = aws_kms_key.security_key.key_id
}

# Security group for monitoring (if needed)
resource "aws_security_group" "monitoring" {
  count = var.monitoring_enabled ? 1 : 0
  
  name_prefix = "${var.environment}-monitoring-"
  description = "Security group for monitoring services"

  # Allow HTTPS outbound for CloudWatch
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound for CloudWatch"
  }

  # Allow HTTP outbound for health checks
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound for health checks"
  }

  tags = merge(local.common_security_tags, {
    Name = "${var.environment}-monitoring-sg"
    Purpose = "Monitoring"
  })
}

# CloudTrail for audit logging (if not already configured)
resource "aws_cloudtrail" "security_audit" {
  count = var.environment == "production" ? 1 : 0
  
  name                          = "${var.environment}-security-audit"
  s3_bucket_name               = aws_s3_bucket.cloudtrail_logs[0].bucket
  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/*"]
    }
  }

  tags = merge(local.common_security_tags, {
    Name = "${var.environment}-security-audit"
    Purpose = "Audit Logging"
  })
}

# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  count = var.environment == "production" ? 1 : 0
  
  bucket = "${var.environment}-cloudtrail-logs-${random_id.cloudtrail_suffix[0].hex}"

  tags = merge(local.common_security_tags, {
    Name = "${var.environment}-cloudtrail-logs"
    Purpose = "Audit Logging"
  })
}

resource "random_id" "cloudtrail_suffix" {
  count = var.environment == "production" ? 1 : 0
  
  byte_length = 4
}

# S3 bucket versioning for CloudTrail logs
resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  count = var.environment == "production" ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption for CloudTrail logs
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  count = var.environment == "production" ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.security_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# S3 bucket public access block for CloudTrail logs
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  count = var.environment == "production" ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for CloudTrail logs
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  count = var.environment == "production" ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs[0].arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.environment}-security-audit"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs[0].arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${var.environment}-security-audit"
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Config rules for compliance monitoring
resource "aws_config_configuration_recorder" "security_compliance" {
  count = var.environment == "production" ? 1 : 0
  
  name     = "${var.environment}-security-compliance"
  role_arn = aws_iam_role.config_role[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [aws_config_delivery_channel.security_compliance]
}

resource "aws_config_delivery_channel" "security_compliance" {
  count = var.environment == "production" ? 1 : 0
  
  name           = "${var.environment}-security-compliance"
  s3_bucket_name = aws_s3_bucket.config_logs[0].bucket
}

# S3 bucket for Config logs
resource "aws_s3_bucket" "config_logs" {
  count = var.environment == "production" ? 1 : 0
  
  bucket = "${var.environment}-config-logs-${random_id.config_suffix[0].hex}"

  tags = merge(local.common_security_tags, {
    Name = "${var.environment}-config-logs"
    Purpose = "Compliance Monitoring"
  })
}

resource "random_id" "config_suffix" {
  count = var.environment == "production" ? 1 : 0
  
  byte_length = 4
}

# IAM role for Config
resource "aws_iam_role" "config_role" {
  count = var.environment == "production" ? 1 : 0
  
  name = "${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_security_tags, {
    Name = "${var.environment}-config-role"
    Purpose = "Compliance Monitoring"
  })
}

resource "aws_iam_role_policy_attachment" "config_role" {
  count = var.environment == "production" ? 1 : 0
  
  role       = aws_iam_role.config_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}
