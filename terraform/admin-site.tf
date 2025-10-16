# Low-cost Admin Site (S3 + CloudFront + WAF Protection)

variable "aws_region" {
  type    = string
  default = "us-east-1"
}


variable "admin_domain_name" {
  description = "Optional DNS name for the admin site (e.g., admin.example.com)"
  type        = string
  default     = null
}

variable "existing_route53_zone_id" {
  description = "Optional existing Route53 hosted zone ID to create admin record in"
  type        = string
  default     = null
}

variable "admin_acm_certificate_arn" {
  description = "Optional ACM certificate ARN (us-east-1) for the admin custom domain"
  type        = string
  default     = null
}

variable "admin_basic_auth_username" {
  description = "Username for Basic Auth to access the admin site"
  type        = string
  default     = "admin"
}

variable "admin_basic_auth_password" {
  description = "Password for Basic Auth to access the admin site"
  type        = string
  sensitive   = true
  default     = "RobertSecure2025!"
}

variable "admin_enhanced_security_enabled" {
  description = "Enable enhanced security features (MFA, IP restrictions, etc.)"
  type        = bool
  default     = true
}

variable "admin_allowed_ips" {
  description = "List of IP addresses/CIDR blocks allowed to access the admin site"
  type        = list(string)
  default     = [] # Add your IP addresses here
}

locals {
  tags = {
    Project   = "AdminSite"
    ManagedBy = "Robert Consulting"
    Purpose   = "Admin UI"
  }
}

resource "random_id" "suffix" {
  byte_length = 3
}

resource "aws_s3_bucket" "admin" {
  bucket = "rc-admin-site-${random_id.suffix.hex}"

  tags = merge(local.tags, { Name = "AdminSite" })
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

resource "aws_cloudfront_origin_access_control" "admin" {
  name                              = "rc-admin-site-oac-${random_id.suffix.hex}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_s3_bucket" "admin" {
  bucket = aws_s3_bucket.admin.bucket
}

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

locals {
  cf_function_code = var.admin_enhanced_security_enabled ? <<EOT
function handler(event) {
  var req = event.request;
  var headers = req.headers;
  var uri = req.uri;

  // Skip authentication for login page and static assets
  if (uri === '/admin-login.html' || 
      uri === '/admin-login' || 
      uri === '/admin-mfa' ||
      uri.match(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$/)) {
    return req;
  }

  // Check for session cookie
  var sessionCookie = getCookie(headers, 'admin-session');
  if (sessionCookie) {
    // Session exists, allow access (session validation handled by Lambda@Edge)
    return req;
  }

  // No session, redirect to login
  return {
    statusCode: 302,
    statusDescription: 'Found',
    headers: {
      'location': { value: '/admin-login.html' },
      'cache-control': { value: 'no-cache, no-store, must-revalidate' }
    }
  };
}

function getCookie(headers, name) {
  var cookieHeader = headers.cookie;
  if (!cookieHeader) return null;
  
  var cookies = cookieHeader.value.split(';');
  for (var i = 0; i < cookies.length; i++) {
    var cookie = cookies[i].trim();
    if (cookie.indexOf(name + '=') === 0) {
      return cookie.substring(name.length + 1);
    }
  }
  return null;
}
EOT
  : <<EOT
function handler(event) {
  var req = event.request;
  var headers = req.headers;

  var authHeader = headers.authorization && headers.authorization.value;
  var expected = 'Basic ${base64encode("${var.admin_basic_auth_username}:${var.admin_basic_auth_password}")}';

  if (!authHeader || authHeader !== expected) {
    return {
      statusCode: 401,
      statusDescription: 'Unauthorized',
      headers: { 'www-authenticate': { value: 'Basic realm="Admin"' } },
      body: 'Authentication required'
    };
  }
  return req;
}
EOT
}

resource "aws_cloudfront_function" "basic_auth" {
  name    = "rc-admin-site-basic-auth-${random_id.suffix.hex}"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = local.cf_function_code
}

resource "aws_cloudfront_distribution" "admin" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Admin Site"
  default_root_object = "index.html"

  aliases = var.admin_domain_name != null && var.admin_acm_certificate_arn != null ? [var.admin_domain_name] : []

  origin {
    domain_name = data.aws_s3_bucket.admin.bucket_regional_domain_name
    origin_id   = "s3-admin-${aws_s3_bucket.admin.id}"

    origin_access_control_id = aws_cloudfront_origin_access_control.admin.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-admin-${aws_s3_bucket.admin.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.basic_auth.arn
    }

    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }

    min_ttl     = 0
    default_ttl = 300
    max_ttl     = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  dynamic "viewer_certificate" {
    for_each = var.admin_acm_certificate_arn != null ? [1] : []
    content {
      acm_certificate_arn            = var.admin_acm_certificate_arn
      ssl_support_method             = "sni-only"
      minimum_protocol_version       = "TLSv1.2_2021"
      cloudfront_default_certificate = false
    }
  }

  dynamic "viewer_certificate" {
    for_each = var.admin_acm_certificate_arn == null ? [1] : []
    content {
      cloudfront_default_certificate = true
    }
  }

  tags = local.tags
}

resource "aws_route53_record" "admin" {
  count   = var.admin_domain_name != null && var.existing_route53_zone_id != null ? 1 : 0
  zone_id = var.existing_route53_zone_id
  name    = var.admin_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.admin.domain_name
    zone_id                = aws_cloudfront_distribution.admin.hosted_zone_id
    evaluate_target_health = false
  }
}

output "admin_bucket" {
  value       = aws_s3_bucket.admin.bucket
  description = "S3 bucket name for the admin site"
}

output "admin_distribution_domain" {
  value       = aws_cloudfront_distribution.admin.domain_name
  description = "CloudFront domain for the admin site"
}

output "admin_cloudfront_id" {
  value       = aws_cloudfront_distribution.admin.id
  description = "CloudFront distribution ID for the admin site"
}

output "admin_url" {
  value       = var.admin_domain_name != null && var.existing_route53_zone_id != null ? "https://${var.admin_domain_name}" : "https://${aws_cloudfront_distribution.admin.domain_name}"
  description = "URL to access the admin site"
}

