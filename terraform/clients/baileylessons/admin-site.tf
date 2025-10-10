# Bailey Lessons Admin Site
# Uses the existing CloudFront distribution E23X7BS3VXFFFZ

variable "admin_basic_auth_username" {
  description = "Username for Basic Auth to access the admin site"
  type        = string
  default     = "bailey_admin"
}

variable "admin_basic_auth_password" {
  description = "Password for Basic Auth to access the admin site"
  type        = string
  sensitive   = true
  default     = "BaileySecure2025!"
}

locals {
  admin_tags = {
    Project   = "BaileyLessons"
    ManagedBy = "Robert Consulting"
    Purpose   = "Admin UI"
    Client    = "Bailey Lessons"
  }
}

# S3 Bucket for admin site
resource "aws_s3_bucket" "admin" {
  bucket = "baileylessons-admin-${random_id.admin_suffix.hex}"

  tags = merge(local.admin_tags, { Name = "BaileyLessonsAdmin" })
}

resource "aws_s3_bucket_public_access_block" "admin" {
  bucket = aws_s3_bucket.admin.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "admin" {
  bucket = aws_s3_bucket.admin.id
  versioning_configuration { status = "Enabled" }
}

# Random ID for unique naming
resource "random_id" "admin_suffix" {
  byte_length = 3
}

# CloudFront Origin Access Control
resource "aws_cloudfront_origin_access_control" "admin" {
  name                              = "baileylessons-admin-oac-${random_id.admin_suffix.hex}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_s3_bucket" "admin" {
  bucket = aws_s3_bucket.admin.bucket
}

# S3 Bucket Policy
resource "aws_s3_bucket_policy" "admin" {
  bucket = aws_s3_bucket.admin.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudFrontOAC",
        Effect = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action = [
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.admin.arn}/*"
        ],
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.admin.arn
          }
        }
      }
    ]
  })
}

# CloudFront Function for Basic Auth
locals {
  cf_function_code = <<EOT
function handler(event) {
  var req = event.request;
  var headers = req.headers;

  var authHeader = headers.authorization && headers.authorization.value;
  var expected = 'Basic ${base64encode("${var.admin_basic_auth_username}:${var.admin_basic_auth_password}")}';

  if (!authHeader || authHeader !== expected) {
    return {
      statusCode: 401,
      statusDescription: 'Unauthorized',
      headers: { 'www-authenticate': { value: 'Basic realm="Bailey Lessons Admin"' } },
      body: 'Authentication required'
    };
  }
  return req;
}
EOT
}

resource "aws_cloudfront_function" "basic_auth" {
  name    = "baileylessons-admin-basic-auth-${random_id.admin_suffix.hex}"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = local.cf_function_code
}

# CloudFront Distribution for Admin Site
resource "aws_cloudfront_distribution" "admin" {
  is_ipv6_enabled     = true
  comment             = "Bailey Lessons Admin Site"
  default_root_object = "index.html"

  aliases = ["admin.baileylessons.com"]

  origin {
    domain_name = data.aws_s3_bucket.admin.bucket_regional_domain_name
    origin_id   = "s3-admin-${aws_s3_bucket.admin.id}"

    origin_access_control_id = aws_cloudfront_origin_access_control.admin.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-admin-${aws_s3_bucket.admin.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.basic_auth.arn
    }

    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["Authorization", "CloudFront-Forwarded-Proto", "CloudFront-Is-Desktop-Viewer", "CloudFront-Is-Mobile-Viewer", "CloudFront-Is-Tablet-Viewer", "CloudFront-Viewer-Country"]
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.baileylessons.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = local.admin_tags
}

# Get existing ACM certificate for baileylessons.com
data "aws_acm_certificate" "baileylessons" {
  domain   = "baileylessons.com"
  statuses = ["ISSUED"]
}

# Route53 Record for admin subdomain
resource "aws_route53_record" "admin" {
  zone_id = "Z01009052GCOJI1M2TTF7" # baileylessons.com zone
  name    = "admin.baileylessons.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.admin.domain_name
    zone_id                = aws_cloudfront_distribution.admin.hosted_zone_id
    evaluate_target_health = false
  }
}

# Outputs
output "admin_bucket" {
  value       = aws_s3_bucket.admin.bucket
  description = "S3 bucket name for the Bailey Lessons admin site"
}

output "admin_distribution_domain" {
  value       = aws_cloudfront_distribution.admin.domain_name
  description = "CloudFront domain for the Bailey Lessons admin site"
}

output "admin_url" {
  value       = "https://admin.baileylessons.com"
  description = "URL to access the Bailey Lessons admin site"
}

output "admin_credentials" {
  value = {
    username = var.admin_basic_auth_username
    password = var.admin_basic_auth_password
  }
  description = "Admin site credentials"
  sensitive   = true
}
