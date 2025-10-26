# Bailey Lessons Migration Configuration
# This file will gradually import baileylessons resources into our module

# Bailey Lessons Module
module "baileylessons" {
  source = "./modules/baileylessons"
  
  # Use existing production values
  client_name        = "baileylessons"
  client_domain      = "baileylessons.com"
  additional_domains = ["www.baileylessons.com", "app.baileylessons.com"]
  environment        = "production"
  aws_region         = "us-east-1"
  
  # Certificate configuration
  create_certificate = false  # Certificate exists in baileylessons account (737915157697)
  
  # Existing resource IDs (will be imported)
  existing_cloudfront_distribution_id = "E23X7BS3VXFFFZ"
  existing_route53_zone_id            = "Z01009052GCOJI1M2TTF7"
  
  # Admin credentials (will be imported from existing)
  admin_basic_auth_username = "bailey_admin"
  admin_basic_auth_password = var.baileylessons_admin_password
}

# Variable for baileylessons admin password
variable "baileylessons_admin_password" {
  description = "Admin basic auth password for baileylessons"
  type        = string
  sensitive   = true
}
