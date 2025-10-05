# AWS Organizations Configuration
# Management account for Robert Consulting with client accounts

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider configuration for the management account
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Organization = "Robert Consulting"
      Environment  = "Management"
      Purpose      = "Client Infrastructure Management"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region for the organization"
  type        = string
  default     = "us-east-1"
}

variable "client_accounts" {
  description = "Map of client accounts to create"
  type        = map(object({
    email     = string
    name      = string
    domain    = string
    tags      = map(string)
  }))
  default = {
    baileylessons = {
      email  = "admin@baileylessons.com"
      name   = "Bailey Lessons"
      domain = "baileylessons.com"
      tags = {
        Client     = "Bailey Lessons"
        Purpose    = "Educational Platform"
        Environment = "Production"
      }
    }
  }
}

# Create the organization (if not already exists)
resource "aws_organizations_organization" "main" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com",
    "access-analyzer.amazonaws.com"
  ]

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]

  feature_set = "ALL"

  tags = {
    Name        = "Robert Consulting Organization"
    Purpose     = "Multi-Client Infrastructure Management"
    Environment = "Management"
  }
}

# Create organizational units for better structure
resource "aws_organizations_organizational_unit" "clients" {
  name      = "Client Accounts"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name = "Client Accounts OU"
    Purpose = "Client Infrastructure"
  }
}

resource "aws_organizations_organizational_unit" "shared_services" {
  name      = "Shared Services"
  parent_id = aws_organizations_organization.main.roots[0].id

  tags = {
    Name = "Shared Services OU"
    Purpose = "Shared Infrastructure Components"
  }
}

# Create client accounts
resource "aws_organizations_account" "clients" {
  for_each = var.client_accounts

  name  = each.value.name
  email = each.value.email

  # Move to clients OU
  parent_id = aws_organizations_organizational_unit.clients.id

  # Enable IAM user access to billing (for cost management)
  iam_user_access_to_billing = "ALLOW"

  tags = merge(each.value.tags, {
    Domain = each.value.domain
    Client = each.key
  })

  # Ensure the account is created before proceeding
  depends_on = [aws_organizations_organization.main]
}

# Service Control Policies for security and governance
resource "aws_organizations_policy" "client_scp" {
  name        = "ClientAccountSCP"
  description = "Service Control Policy for client accounts"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyRootActions"
        Effect = "Deny"
        Action = [
          "iam:DeleteAccountPasswordPolicy",
          "iam:DeleteAccountAlias",
          "iam:DeleteAccount",
          "organizations:LeaveOrganization"
        ]
        Resource = "*"
      },
      {
        Sid    = "RequireMFA"
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      },
      {
        Sid    = "DenyDirectInternetAccess"
        Effect = "Deny"
        Action = [
          "ec2:CreateInternetGateway",
          "ec2:AttachInternetGateway"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach SCP to client accounts
resource "aws_organizations_policy_attachment" "client_scp" {
  for_each = aws_organizations_account.clients

  policy_id = aws_organizations_policy.client_scp.id
  target_id = each.value.id
}

# Tag policy for consistent tagging
resource "aws_organizations_policy" "tag_policy" {
  name        = "TagPolicy"
  description = "Tag policy for consistent resource tagging"
  type        = "TAG_POLICY"

  content = jsonencode({
    tags = {
      Environment = {
        tag_key = {
          "@@assign" = ["Production", "Staging", "Development", "Testing"]
        }
      }
      Client = {
        tag_key = {
          "@@assign" = ["baileylessons", "robert-consulting"]
        }
      }
      Purpose = {
        tag_key = {
          "@@assign" = ["Web Hosting", "Educational Platform", "Management", "Monitoring"]
        }
      }
    }
  })
}

# Attach tag policy to organization
resource "aws_organizations_policy_attachment" "tag_policy" {
  policy_id = aws_organizations_policy.tag_policy.id
  target_id = aws_organizations_organization.main.roots[0].id
}

# Outputs
output "organization_id" {
  description = "AWS Organizations ID"
  value       = aws_organizations_organization.main.id
}

output "client_accounts" {
  description = "Created client accounts"
  value = {
    for k, v in aws_organizations_account.clients : k => {
      id    = v.id
      name  = v.name
      email = v.email
      arn   = v.arn
    }
  }
}

