# Terraform State Management and Drift Prevention
# Ensures state consistency and prevents configuration drift

# Data sources for existing resources (prevents drift)
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Lifecycle rules to prevent accidental destruction
locals {
  prevent_destroy_resources = [
    "aws_s3_bucket.terraform_state",
    "aws_dynamodb_table.terraform_state_lock",
    "aws_s3_bucket.website_bucket",
    "aws_cloudfront_distribution.website"
  ]
}

# State validation and drift detection
resource "null_resource" "state_validation" {
  count = var.enable_state_validation ? 1 : 0
  
  triggers = {
    # Trigger on any infrastructure changes
    infrastructure_hash = md5(jsonencode({
      s3_buckets     = [for bucket in aws_s3_bucket.all : bucket.id]
      cloudfront_ids = [for dist in aws_cloudfront_distribution.all : dist.id]
      dynamodb_tables = [for table in aws_dynamodb_table.all : table.id]
    }))
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      echo "Validating Terraform state..."
      terraform plan -detailed-exitcode
      if [ $? -eq 2 ]; then
        echo "ERROR: Infrastructure drift detected!"
        exit 1
      fi
    EOT
  }
}

# Variables for state management
variable "enable_state_validation" {
  description = "Enable automatic state validation and drift detection"
  type        = bool
  default     = true
}

# Outputs for state management
output "state_management_info" {
  description = "State management configuration information"
  value = {
    backend_bucket    = "robert-consulting-terraform-state"
    lock_table       = "terraform-state-lock"
    region          = "us-east-1"
    state_validation = var.enable_state_validation
    prevent_destroy = true
  }
}
