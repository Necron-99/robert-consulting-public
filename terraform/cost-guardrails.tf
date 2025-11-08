# Cost Guardrails - AWS Budgets + Rate Limiting
# Solution 1: AWS Budgets with automatic actions
# Solution 2: DynamoDB-based rate limiting infrastructure

# =============================================================================
# SOLUTION 1: AWS BUDGETS
# =============================================================================

# Daily cost budget with automatic actions
resource "aws_budgets_budget" "daily_cost_guardrail" {
  name              = "daily-cost-guardrail"
  budget_type       = "COST"
  limit_amount      = "10"  # $10/day threshold
  limit_unit        = "USD"
  time_period_start = "2025-01-01_00:00"
  time_unit         = "DAILY"

  # Alert at 50% ($5)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 50
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["rsbailey@necron99.org"]
  }

  # Alert at 80% ($8)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["rsbailey@necron99.org"]
  }

  # Alert at 100% ($10) - critical
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["rsbailey@necron99.org"]
  }

  tags = {
    Name        = "Daily Cost Guardrail"
    Purpose     = "cost-protection"
    ManagedBy   = "Terraform"
  }
}

# Monthly cost budget (backup protection)
resource "aws_budgets_budget" "monthly_cost_guardrail" {
  name              = "monthly-cost-guardrail"
  budget_type       = "COST"
  limit_amount      = "100"  # $100/month threshold
  limit_unit        = "USD"
  time_period_start = "2025-01-01_00:00"
  time_unit         = "MONTHLY"

  # Alert at 80% ($80)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["rsbailey@necron99.org"]
  }

  # Alert at 100% ($100) - critical
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["rsbailey@necron99.org"]
  }

  tags = {
    Name        = "Monthly Cost Guardrail"
    Purpose     = "cost-protection"
    ManagedBy   = "Terraform"
  }
}

# IAM role for budget actions
resource "aws_iam_role" "budget_action_role" {
  name = "budget-action-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "budgets.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name      = "Budget Action Role"
    Purpose   = "cost-protection"
    ManagedBy  = "Terraform"
  }
}

# IAM policy to deny Lambda invocations when budget exceeded
resource "aws_iam_policy" "lambda_disable_policy" {
  name        = "disable-lambdas-on-budget-exceeded"
  description = "Denies Lambda invocations when daily budget is exceeded"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = [
        "arn:aws:lambda:*:*:function:robert-consulting-dashboard-api",
        "arn:aws:lambda:*:*:function:robert-consulting-stats-refresher",
        "arn:aws:lambda:*:*:function:robert-consulting-terraform-stats-refresher"
      ]
    }]
  })

  tags = {
    Name      = "Lambda Disable Policy"
    Purpose   = "cost-protection"
    ManagedBy = "Terraform"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "budget_action_policy" {
  role       = aws_iam_role.budget_action_role.name
  policy_arn = aws_iam_policy.lambda_disable_policy.arn
}

# Budget action to disable Lambda functions if threshold exceeded
# NOTE: This is commented out by default as it can be disruptive
# Uncomment and configure if you want automatic Lambda disabling
# resource "aws_budgets_budget_action" "disable_lambdas" {
#   budget_name = aws_budgets_budget.daily_cost_guardrail.name
#   action_type = "APPLY_IAM_POLICY"
#   
#   action_threshold {
#     action_threshold_value = 100  # Trigger at 100% of budget
#     action_threshold_type  = "PERCENTAGE"
#   }
#
#   definition {
#     iam_action_definition {
#       policy_arn = aws_iam_policy.lambda_disable_policy.arn
#       roles      = [aws_iam_role.budget_action_role.name]
#     }
#   }
#
#   approval_model = "AUTOMATIC"
#   execution_role_arn = aws_iam_role.budget_action_role.arn
#   notification_type = "ACTUAL"
# }

# =============================================================================
# SOLUTION 2: DYNAMODB RATE LIMITING INFRASTRUCTURE
# =============================================================================

# DynamoDB table for API rate limiting
resource "aws_dynamodb_table" "api_rate_limits" {
  name           = "api-rate-limits"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "apiCall"

  attribute {
    name = "apiCall"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "API Rate Limits"
    Purpose     = "cost-control"
    ManagedBy   = "Terraform"
  }
}

# DynamoDB table for API cost tracking
resource "aws_dynamodb_table" "api_cost_tracking" {
  name           = "api-cost-tracking"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "date"

  attribute {
    name = "date"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "API Cost Tracking"
    Purpose     = "cost-control"
    ManagedBy   = "Terraform"
  }
}

# SNS topic for cost alerts from rate limiting
resource "aws_sns_topic" "api_cost_alerts" {
  name = "api-cost-alerts"

  tags = {
    Name        = "API Cost Alerts"
    Purpose     = "cost-control"
    ManagedBy   = "Terraform"
  }
}

resource "aws_sns_topic_subscription" "api_cost_alerts_email" {
  topic_arn = aws_sns_topic.api_cost_alerts.arn
  protocol  = "email"
  endpoint  = "rsbailey@necron99.org"
}

# IAM policy for Lambda functions to access rate limiting tables
resource "aws_iam_policy" "rate_limiting_access" {
  name        = "rate-limiting-dynamodb-access"
  description = "Allows Lambda functions to access rate limiting DynamoDB tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.api_rate_limits.arn,
          aws_dynamodb_table.api_cost_tracking.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.api_cost_alerts.arn
      }
    ]
  })

  tags = {
    Name      = "Rate Limiting Access Policy"
    Purpose   = "cost-control"
    ManagedBy = "Terraform"
  }
}

# Outputs
output "budget_daily_arn" {
  description = "ARN of the daily cost budget"
  value       = aws_budgets_budget.daily_cost_guardrail.arn
}

output "budget_monthly_arn" {
  description = "ARN of the monthly cost budget"
  value       = aws_budgets_budget.monthly_cost_guardrail.arn
}

output "rate_limiting_table_name" {
  description = "Name of the rate limiting DynamoDB table"
  value       = aws_dynamodb_table.api_rate_limits.name
}

output "cost_tracking_table_name" {
  description = "Name of the cost tracking DynamoDB table"
  value       = aws_dynamodb_table.api_cost_tracking.name
}

output "api_cost_alerts_topic_arn" {
  description = "ARN of the SNS topic for API cost alerts"
  value       = aws_sns_topic.api_cost_alerts.arn
}

