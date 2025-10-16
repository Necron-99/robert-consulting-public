# Enhanced Security for Admin Site
# Multi-layer security implementation with MFA, IP restrictions, and advanced monitoring

variable "admin_mfa_enabled" {
  description = "Enable multi-factor authentication for admin site"
  type        = bool
  default     = true
}

variable "admin_allowed_ips" {
  description = "List of IP addresses/CIDR blocks allowed to access the admin site"
  type        = list(string)
  default     = [] # Add your IP addresses here
}

variable "admin_session_timeout" {
  description = "Session timeout in minutes"
  type        = number
  default     = 30
}

variable "admin_max_login_attempts" {
  description = "Maximum login attempts before lockout"
  type        = number
  default     = 3
}

variable "admin_lockout_duration" {
  description = "Lockout duration in minutes"
  type        = number
  default     = 15
}

locals {
  security_tags = {
    Project   = "AdminSite"
    ManagedBy = "Robert Consulting"
    Purpose   = "Enhanced Security"
    Security  = "High"
  }
}

# Random ID for unique naming
resource "random_id" "security_suffix" {
  byte_length = 4
}

# Secrets Manager for storing sensitive security data
resource "aws_secretsmanager_secret" "admin_security" {
  name                    = "rc-admin-security-${random_id.security_suffix.hex}"
  description             = "Admin site security configuration and secrets"
  recovery_window_in_days = 7

  tags = local.security_tags
}

resource "aws_secretsmanager_secret_version" "admin_security" {
  secret_id = aws_secretsmanager_secret.admin_security.id
  secret_string = jsonencode({
    jwt_secret_key        = random_password.jwt_secret.result
    mfa_secret_key        = random_password.mfa_secret.result
    session_encryption_key = random_password.session_key.result
    admin_password_hash   = bcrypt(var.admin_basic_auth_password, 12)
    allowed_ips           = var.admin_allowed_ips
    session_timeout       = var.admin_session_timeout
    max_login_attempts    = var.admin_max_login_attempts
    lockout_duration      = var.admin_lockout_duration
  })
}

# Generate secure random passwords
resource "random_password" "jwt_secret" {
  length  = 64
  special = true
}

resource "random_password" "mfa_secret" {
  length  = 32
  special = false
}

resource "random_password" "session_key" {
  length  = 32
  special = true
}

# DynamoDB table for session management and audit logging
resource "aws_dynamodb_table" "admin_sessions" {
  name           = "rc-admin-sessions-${random_id.security_suffix.hex}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "session_id"
  range_key      = "created_at"

  attribute {
    name = "session_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  attribute {
    name = "user_ip"
    type = "S"
  }

  global_secondary_index {
    name     = "user-ip-index"
    hash_key = "user_ip"
    projection_type = "ALL"
  }

  global_secondary_index {
    name     = "expires-index"
    hash_key = "expires_at"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = local.security_tags
}

resource "aws_dynamodb_table" "admin_audit_log" {
  name           = "rc-admin-audit-${random_id.security_suffix.hex}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "timestamp"
  range_key      = "action_id"

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "action_id"
    type = "S"
  }

  attribute {
    name = "user_ip"
    type = "S"
  }

  global_secondary_index {
    name     = "user-ip-index"
    hash_key = "user_ip"
    projection_type = "ALL"
  }

  global_secondary_index {
    name     = "action-type-index"
    hash_key = "action_type"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = local.security_tags
}

# Lambda function for enhanced authentication
resource "aws_lambda_function" "admin_auth" {
  filename         = data.archive_file.admin_auth_zip.output_path
  function_name    = "rc-admin-auth-${random_id.security_suffix.hex}"
  role            = aws_iam_role.admin_auth_role.arn
  handler         = "admin-auth.handler"
  runtime         = "nodejs22.x"
  timeout         = 30
  memory_size     = 256

  environment {
    variables = {
      SECRETS_MANAGER_SECRET_ID = aws_secretsmanager_secret.admin_security.id
      SESSIONS_TABLE_NAME       = aws_dynamodb_table.admin_sessions.name
      AUDIT_TABLE_NAME          = aws_dynamodb_table.admin_audit_log.name
      MFA_ENABLED               = var.admin_mfa_enabled
    }
  }

  tags = local.security_tags
}

# Lambda function code
data "archive_file" "admin_auth_zip" {
  type        = "zip"
  output_path = "/tmp/admin-auth.zip"
  source_dir  = "${path.module}/../lambda"
  excludes    = ["package-lock.json", "node_modules"]
}

# IAM role for Lambda function
resource "aws_iam_role" "admin_auth_role" {
  name = "rc-admin-auth-role-${random_id.security_suffix.hex}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.security_tags
}

resource "aws_iam_role_policy" "admin_auth_policy" {
  name = "rc-admin-auth-policy-${random_id.security_suffix.hex}"
  role = aws_iam_role.admin_auth_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.admin_security.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.admin_sessions.arn,
          "${aws_dynamodb_table.admin_sessions.arn}/index/*",
          aws_dynamodb_table.admin_audit_log.arn,
          "${aws_dynamodb_table.admin_audit_log.arn}/index/*"
        ]
      }
    ]
  })
}

# Enhanced WAF Web ACL with advanced security rules
resource "aws_wafv2_web_acl" "admin_enhanced_protection" {
  name  = "rc-admin-enhanced-waf-${random_id.security_suffix.hex}"
  scope = "CLOUDFRONT"

  default_action {
    block {}
  }

  # IP Allowlist (if specified)
  dynamic "rule" {
    for_each = length(var.admin_allowed_ips) > 0 ? [1] : []
    content {
      name     = "AllowAdminIPs"
      priority = 1

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.admin_ips[0].arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AllowAdminIPs"
        sampled_requests_enabled   = true
      }
    }
  }

  # Rate limiting with different limits for different paths
  rule {
    name     = "AdminRateLimit"
    priority = 2

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100  # Very restrictive for admin
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AdminRateLimit"
      sampled_requests_enabled   = true
    }
  }

  # Login attempt rate limiting
  rule {
    name     = "LoginRateLimit"
    priority = 3

    action {
      block {}
    }

    statement {
      and_statement {
        statement {
          byte_match_statement {
            search_string         = "/login"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "CONTAINS"
          }
        }
        statement {
          rate_based_statement {
            limit              = 5  # Max 5 login attempts per IP
            aggregate_key_type = "IP"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "LoginRateLimit"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - Known Bad Inputs
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rules - SQL Injection
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 6

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Custom rule for admin-specific patterns
  rule {
    name     = "AdminSpecificProtection"
    priority = 7

    action {
      block {}
    }

    statement {
      or_statement {
        statement {
          byte_match_statement {
            search_string         = "admin"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "CONTAINS"
          }
        }
        statement {
          byte_match_statement {
            search_string         = "konami"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "CONTAINS"
          }
        }
        statement {
          byte_match_statement {
            search_string         = "easter"
            field_to_match {
              uri_path {}
            }
            text_transformation {
              priority = 0
              type     = "LOWERCASE"
            }
            positional_constraint = "CONTAINS"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AdminSpecificProtection"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "AdminEnhancedProtection"
    sampled_requests_enabled   = true
  }

  tags = local.security_tags
}

# IP Set for allowed IPs
resource "aws_wafv2_ip_set" "admin_ips" {
  count = length(var.admin_allowed_ips) > 0 ? 1 : 0

  name  = "rc-admin-ips-${random_id.security_suffix.hex}"
  scope = "CLOUDFRONT"

  ip_address_version = "IPV4"
  addresses          = var.admin_allowed_ips

  tags = local.security_tags
}

# CloudWatch Log Group for WAF
resource "aws_cloudwatch_log_group" "admin_waf_logs" {
  name              = "/aws/wafv2/admin-${random_id.security_suffix.hex}"
  retention_in_days = 30

  tags = local.security_tags
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "admin_auth_logs" {
  name              = "/aws/lambda/rc-admin-auth-${random_id.security_suffix.hex}"
  retention_in_days = 14

  tags = local.security_tags
}

# CloudWatch Alarms for security monitoring
resource "aws_cloudwatch_metric_alarm" "admin_high_block_rate" {
  alarm_name          = "rc-admin-high-block-rate-${random_id.security_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "High number of blocked requests to admin site"
  alarm_actions       = [aws_sns_topic.admin_security_alerts.arn]

  dimensions = {
    WebACL = aws_wafv2_web_acl.admin_enhanced_protection.name
    Region = "CloudFront"
  }

  tags = local.security_tags
}

resource "aws_cloudwatch_metric_alarm" "admin_failed_logins" {
  alarm_name          = "rc-admin-failed-logins-${random_id.security_suffix.hex}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedLoginAttempts"
  namespace           = "Custom/Admin"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High number of failed login attempts"
  alarm_actions       = [aws_sns_topic.admin_security_alerts.arn]

  tags = local.security_tags
}

# SNS Topic for security alerts
resource "aws_sns_topic" "admin_security_alerts" {
  name = "rc-admin-security-alerts-${random_id.security_suffix.hex}"

  tags = local.security_tags
}

# Outputs
output "admin_security_secret_arn" {
  description = "ARN of the admin security secrets"
  value       = aws_secretsmanager_secret.admin_security.arn
  sensitive   = true
}

output "admin_waf_web_acl_arn" {
  description = "ARN of the enhanced WAF Web ACL"
  value       = aws_wafv2_web_acl.admin_enhanced_protection.arn
}

output "admin_sessions_table_name" {
  description = "Name of the admin sessions DynamoDB table"
  value       = aws_dynamodb_table.admin_sessions.name
}

output "admin_audit_table_name" {
  description = "Name of the admin audit log DynamoDB table"
  value       = aws_dynamodb_table.admin_audit_log.name
}
