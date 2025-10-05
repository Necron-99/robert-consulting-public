# Create a console-friendly role without external ID for easy switching
resource "aws_iam_role" "console_access_role" {
  name = "RobertConsoleAccessRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::228480945348:root"  # Management account
        }
        Action = "sts:AssumeRole"
        # No external ID required for console access
      }
    ]
  })

  description = "Console access role for Robert Consulting management account"
  
  tags = {
    Name        = "RobertConsoleAccessRole"
    Client      = "baileylessons"
    Environment = "production"
    Purpose     = "Console access for management"
    ManagedBy   = "Robert Consulting"
  }
}

# Attach AdministratorAccess policy to the console role
resource "aws_iam_role_policy_attachment" "console_access_admin" {
  role       = aws_iam_role.console_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Output the role ARN for console access
output "console_access_role_arn" {
  description = "ARN of the RobertConsoleAccessRole for console switching"
  value       = aws_iam_role.console_access_role.arn
}
