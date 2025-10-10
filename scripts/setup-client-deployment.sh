#!/bin/bash

# Client Deployment Setup Script
# Sets up deployment configuration for a new client

set -e

# Configuration
CLIENT_NAME="${1:-}"
CLIENT_REPO="${2:-}"
DOMAIN="${3:-}"
REGION="us-east-1"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Usage function
usage() {
    echo "Usage: $0 <client_name> <client_repo> <domain>"
    echo ""
    echo "Parameters:"
    echo "  client_name  - Name of the client (e.g., baileylessons)"
    echo "  client_repo  - GitHub repository (e.g., username/baileylessons.com)"
    echo "  domain       - Client domain (e.g., baileylessons.com)"
    echo ""
    echo "Example:"
    echo "  $0 baileylessons username/baileylessons.com baileylessons.com"
    exit 1
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check required parameters
    if [ -z "$CLIENT_NAME" ] || [ -z "$CLIENT_REPO" ] || [ -z "$DOMAIN" ]; then
        log_error "Missing required parameters"
        usage
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create client configuration
create_client_config() {
    log_info "Creating client configuration..."
    
    # Create client directory
    local client_dir="clients/$CLIENT_NAME"
    mkdir -p "$client_dir"
    
    # Generate S3 bucket name
    local bucket_name="${CLIENT_NAME}-website-$(date +%Y%m%d)-$(openssl rand -hex 4)"
    
    # Create configuration file
    cat > "$client_dir/config.json" << EOF
{
  "client_name": "$CLIENT_NAME",
  "client_repo": "$CLIENT_REPO",
  "domain": "$DOMAIN",
  "s3_bucket": "$bucket_name",
  "cloudfront_distribution_id": "",
  "region": "$REGION",
  "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "status": "pending_setup"
}
EOF
    
    log_success "Client configuration created: $client_dir/config.json"
    echo "$bucket_name"
}

# Create Terraform configuration
create_terraform_config() {
    local bucket_name="$1"
    local client_dir="clients/$CLIENT_NAME"
    
    log_info "Creating Terraform configuration..."
    
    # Create Terraform files
    cat > "$client_dir/main.tf" << EOF
# Client Infrastructure: $CLIENT_NAME
# Domain: $DOMAIN

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "robert-consulting-terraform-state"
    key    = "clients/$CLIENT_NAME/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "$REGION"
}

variable "domain_name" {
  description = "Domain name for the website"
  type        = string
  default     = "$DOMAIN"
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "$bucket_name"
}

# S3 Bucket for website hosting
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name

  tags = {
    Name        = "\${var.domain_name} Website"
    Client      = "$CLIENT_NAME"
    Environment = "production"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "\${aws_s3_bucket.website.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.website]
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.website.website_endpoint
    origin_id   = "S3-\${var.bucket_name}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [var.domain_name]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-\${var.bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "\${var.domain_name} Distribution"
    Client      = "$CLIENT_NAME"
    Environment = "production"
  }
}

# Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.bucket
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "website_url" {
  description = "Website URL"
  value       = "https://\${aws_cloudfront_distribution.website.domain_name}"
}
EOF
    
    log_success "Terraform configuration created: $client_dir/main.tf"
}

# Create deployment script
create_deployment_script() {
    local client_dir="clients/$CLIENT_NAME"
    
    log_info "Creating deployment script..."
    
    cat > "$client_dir/deploy.sh" << 'EOF'
#!/bin/bash

# Client-specific deployment script
# Generated by setup-client-deployment.sh

set -e

# Load configuration
CONFIG_FILE="config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Parse configuration
CLIENT_NAME=$(jq -r '.client_name' "$CONFIG_FILE")
CLIENT_REPO=$(jq -r '.client_repo' "$CONFIG_FILE")
BUCKET_NAME=$(jq -r '.s3_bucket' "$CONFIG_FILE")
CLOUDFRONT_ID=$(jq -r '.cloudfront_distribution_id' "$CONFIG_FILE")

# Check if CloudFront ID is set
if [ "$CLOUDFRONT_ID" = "null" ] || [ -z "$CLOUDFRONT_ID" ]; then
    echo "Error: CloudFront distribution ID not set in configuration"
    echo "Please run 'terraform apply' first to create the infrastructure"
    exit 1
fi

# Run deployment
echo "Deploying $CLIENT_NAME from $CLIENT_REPO..."
../../scripts/deploy-client-content.sh "$CLIENT_NAME" "$CLIENT_REPO" "$BUCKET_NAME" "$CLOUDFRONT_ID"
EOF
    
    chmod +x "$client_dir/deploy.sh"
    log_success "Deployment script created: $client_dir/deploy.sh"
}

# Create README
create_readme() {
    local bucket_name="$1"
    local client_dir="clients/$CLIENT_NAME"
    
    log_info "Creating README..."
    
    cat > "$client_dir/README.md" << EOF
# $CLIENT_NAME Client Infrastructure

This directory contains the infrastructure and deployment configuration for $CLIENT_NAME.

## Configuration

- **Client Name**: $CLIENT_NAME
- **Repository**: $CLIENT_REPO
- **Domain**: $DOMAIN
- **S3 Bucket**: $bucket_name
- **Region**: $REGION

## Setup Instructions

### 1. Deploy Infrastructure

\`\`\`bash
cd clients/$CLIENT_NAME
terraform init
terraform plan
terraform apply
\`\`\`

### 2. Update Configuration

After Terraform deployment, update the CloudFront distribution ID in \`config.json\`:

\`\`\`bash
# Get the CloudFront distribution ID
terraform output cloudfront_distribution_id

# Update config.json with the ID
\`\`\`

### 3. Deploy Content

\`\`\`bash
./deploy.sh
\`\`\`

## Manual Deployment

To deploy content manually:

\`\`\`bash
../../scripts/deploy-client-content.sh $CLIENT_NAME $CLIENT_REPO $bucket_name <cloudfront-id>
\`\`\`

## Files

- \`config.json\` - Client configuration
- \`main.tf\` - Terraform infrastructure definition
- \`deploy.sh\` - Deployment script
- \`README.md\` - This file

## Admin Interface

Access the admin interface at: \`/admin/client-deployment.html\`

## Support

For issues or questions, contact Robert Consulting.
EOF
    
    log_success "README created: $client_dir/README.md"
}

# Main setup function
main() {
    log_info "Setting up client deployment for: $CLIENT_NAME"
    log_info "Repository: $CLIENT_REPO"
    log_info "Domain: $DOMAIN"
    
    # Execute setup steps
    check_prerequisites
    bucket_name=$(create_client_config)
    create_terraform_config "$bucket_name"
    create_deployment_script
    create_readme "$bucket_name"
    
    log_success "Client deployment setup completed!"
    log_info "Next steps:"
    log_info "1. cd clients/$CLIENT_NAME"
    log_info "2. terraform init"
    log_info "3. terraform plan"
    log_info "4. terraform apply"
    log_info "5. Update config.json with CloudFront distribution ID"
    log_info "6. ./deploy.sh"
    
    log_info "Admin interface: /admin/client-deployment.html"
}

# Run main function
main "$@"