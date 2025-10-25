# Backend configuration for Bailey Lessons Terraform state
# This uses a separate S3 bucket for the baileylessons account
# NOTE: Backend will be configured after S3 bucket is created

# terraform {
#   backend "s3" {
#     bucket         = "baileylessons-terraform-state"
#     key            = "terraform.tfstate"
#     region         = "us-east-1"
#     encrypt        = true
#     use_lockfile   = true
#   }
# }
