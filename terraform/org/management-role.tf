# Management Account Role for Remote Client Management
# This role allows the management account to assume remote management roles in client accounts

resource "aws_iam_role" "client_management_role" {
  name = "RobertClientManagementRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::228480945348:user/terraform-user"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  description = "Role for managing client accounts remotely"
  
  tags = {
    Name        = "RobertClientManagementRole"
    Purpose     = "Client account management"
    Environment = "Management"
    ManagedBy   = "Robert Consulting"
  }
}

# Attach policies for client management
resource "aws_iam_role_policy" "client_management_policy" {
  name = "ClientManagementPolicy"
  role = aws_iam_role.client_management_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Assume roles in client accounts
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::737915157697:role/RobertRemoteManagementRole",  # Bailey Lessons
          "arn:aws:iam::*:role/RobertRemoteManagementRole"  # Future clients
        ]
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "robert-consulting-remote-management"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          # Organizations management
          "organizations:*",
          
          # Account management
          "account:*",
          
          # Billing and cost management
          "ce:*",
          "cur:*",
          "budgets:*",
          
          # Security and compliance
          "securityhub:*",
          "guardduty:*",
          "config:*",
          
          # Support access
          "support:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Output the role ARN
output "client_management_role_arn" {
  description = "ARN of the RobertClientManagementRole"
  value       = aws_iam_role.client_management_role.arn
}
