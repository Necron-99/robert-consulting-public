# Secure IAM Policy for Terraform Operations
# Following least privilege and security best practices

# IAM role for Terraform operations
resource "aws_iam_role" "terraform_execution_role" {
  name = "TerraformExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/ManagedBy" = "Terraform"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "Terraform Execution Role"
    Purpose     = "Terraform Infrastructure Management"
    Environment = "Production"
    ManagedBy   = "Terraform"
    Owner       = "Infrastructure Team"
  }
}

# Comprehensive IAM policy for Terraform operations
resource "aws_iam_role_policy" "terraform_execution_policy" {
  name = "TerraformExecutionPolicy"
  role = aws_iam_role.terraform_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
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
      },
      {
        Sid    = "TerraformLockingAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_locks.arn
      },
      {
        Sid    = "TerraformCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "TerraformEC2Access"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformS3Access"
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformCloudFrontAccess"
        Effect = "Allow"
        Action = [
          "cloudfront:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformRoute53Access"
        Effect = "Allow"
        Action = [
          "route53:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformLambdaAccess"
        Effect = "Allow"
        Action = [
          "lambda:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformAPIGatewayAccess"
        Effect = "Allow"
        Action = [
          "apigateway:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformIAMAccess"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:SetDefaultPolicyVersion"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformSecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformSSMAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      }
    ]
  })
}

# Output the role ARN for use in CI/CD
output "terraform_execution_role_arn" {
  description = "ARN of the Terraform execution role"
  value       = aws_iam_role.terraform_execution_role.arn
  sensitive   = false
}

output "terraform_execution_role_name" {
  description = "Name of the Terraform execution role"
  value       = aws_iam_role.terraform_execution_role.name
  sensitive   = false
}
