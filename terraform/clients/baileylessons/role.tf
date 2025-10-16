# Create RobertClientDeploymentRole in the client account
# This role will be assumed by the management account for deployments

resource "aws_iam_role" "client_deployment_role" {
  name = "RobertClientDeploymentRole"
  
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
            "sts:ExternalId" = "robert-consulting-deployment"
          }
        }
      }
    ]
  })

  description = "Deployment role assumed by Robert Consulting management account"
  
  tags = {
    Name        = "RobertClientDeploymentRole"
    Client      = "baileylessons"
    Environment = "production"
    Purpose     = "Cross-account deployment access"
    ManagedBy   = "Robert Consulting"
  }
}

# Attach AdministratorAccess policy to the role
resource "aws_iam_role_policy_attachment" "client_deployment_admin" {
  role       = aws_iam_role.client_deployment_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Output the role ARN for verification
output "client_deployment_role_arn" {
  description = "ARN of the RobertClientDeploymentRole in the client account"
  value       = aws_iam_role.client_deployment_role.arn
}
