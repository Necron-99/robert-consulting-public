# Remote Management Role for Client Accounts
# This role allows the management account to manage resources in client accounts

resource "aws_iam_role" "remote_management_role" {
  name = "RobertRemoteManagementRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"  # Management account
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "robert-consulting-remote-management"
          }
        }
      }
    ]
  })

  description = "Remote management role for Robert Consulting to manage client resources"
  
  tags = merge(local.common_tags, {
    Name        = "RobertRemoteManagementRole"
    Purpose     = "Remote resource management"
    AccessLevel = "Management"
  })
}

# Attach comprehensive management policies
resource "aws_iam_role_policy_attachment" "remote_management_admin" {
  role       = aws_iam_role.remote_management_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Additional specific policies for common management tasks
resource "aws_iam_role_policy" "remote_management_additional" {
  name = "RemoteManagementAdditional"
  role = aws_iam_role.remote_management_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Cost and billing management
          "ce:*",
          "cur:*",
          "budgets:*",
          "pricing:*",
          
          # Security and compliance
          "securityhub:*",
          "guardduty:*",
          "inspector:*",
          "config:*",
          "access-analyzer:*",
          
          # Monitoring and logging
          "logs:*",
          "cloudwatch:*",
          "xray:*",
          
          # Support and case management
          "support:*",
          "trustedadvisor:*",
          
          # Resource tagging and organization
          "tag:*",
          "resource-groups:*",
          "resourcegroupstaggingapi:*",
          
          # Cross-account access
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          # Assume roles in other accounts for multi-account management
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/RobertRemoteManagementRole",
          "arn:aws:iam::*:role/OrganizationAccountAccessRole"
        ]
      }
    ]
  })
}

# Output the role ARN for use in management account
output "remote_management_role_arn" {
  description = "ARN of the RobertRemoteManagementRole for remote management"
  value       = aws_iam_role.remote_management_role.arn
}

# Output role name for easy reference
output "remote_management_role_name" {
  description = "Name of the RobertRemoteManagementRole"
  value       = aws_iam_role.remote_management_role.name
}
