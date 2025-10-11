# Core Infrastructure Configuration
# This file contains only infrastructure resources, decoupled from website content

# S3 bucket for website hosting
resource "aws_s3_bucket" "website_bucket" {
  bucket = "robert-consulting-website"
  
  tags = {
    Name        = "Robert Consulting Website"
    Environment = "Production"
    Purpose     = "Static Website Hosting"
    ManagedBy   = "Terraform"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block (allow public policies for website)
resource "aws_s3_bucket_public_access_block" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 bucket policy for public read access
resource "aws_s3_bucket_policy" "website_bucket" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

# CloudFront response headers policy for security headers
resource "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "security-headers-policy"

  security_headers_config {
    content_type_options {
      override = false
    }
    frame_options {
      frame_option = "DENY"
      override     = false
    }
    referrer_policy {
      referrer_policy = "strict-origin-when-cross-origin"
      override        = false
    }
    strict_transport_security {
      access_control_max_age_sec = 31536000
      include_subdomains         = true
      preload                    = true
      override                   = false
    }
  }

         custom_headers_config {
           items {
             header   = "Permissions-Policy"
             value    = "camera=(), microphone=(), geolocation=(), payment=(), usb=()"
             override = false
           }
           items {
             header   = "Cross-Origin-Embedder-Policy"
             value    = "require-corp"
             override = false
           }
           items {
             header   = "Cross-Origin-Opener-Policy"
             value    = "same-origin"
             override = false
           }
           items {
             header   = "Cross-Origin-Resource-Policy"
             value    = "same-origin"
             override = false
           }
           items {
             header   = "X-DNS-Prefetch-Control"
             value    = "off"
             override = false
           }
           items {
             header   = "X-Download-Options"
             value    = "noopen"
             override = false
           }
           items {
             header   = "X-Permitted-Cross-Domain-Policies"
             value    = "none"
             override = false
           }
         }

         # Remove server headers to prevent information disclosure
         remove_headers_config {
           items {
             header = "Server"
           }
           items {
             header = "X-Powered-By"
           }
           items {
             header = "X-AspNet-Version"
           }
           items {
             header = "X-AspNetMvc-Version"
           }
         }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.website_bucket.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.website_bucket.bucket}"

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

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.website_bucket.bucket}"
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400

    # Security headers to address ZAP findings
    response_headers_policy_id = aws_cloudfront_response_headers_policy.security_headers.id
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.wildcard.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = ["robertconsulting.net", "www.robertconsulting.net"]
  
  tags = {
    Name        = "Robert Consulting Website CDN"
    Environment = "Production"
    Purpose     = "Content Delivery"
    ManagedBy   = "Terraform"
  }
  
  lifecycle {
    prevent_destroy = true
  }
}

# Outputs for infrastructure
output "website_bucket_name" {
  description = "Name of the S3 bucket for website hosting"
  value       = aws_s3_bucket.website_bucket.bucket
}

output "website_bucket_website_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = aws_s3_bucket_website_configuration.website_bucket.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_distribution_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website.arn
}
