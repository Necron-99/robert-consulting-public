# Testing Site S3 Bucket Configuration
# This creates a single, properly configured testing bucket with correct public access settings

# S3 bucket for testing site
resource "aws_s3_bucket" "testing_site" {
  bucket = "robert-consulting-testing-terraform"

  tags = {
    Name        = "Robert Consulting Testing Site"
    Environment = "Testing"
    Purpose     = "Testing Site Hosting"
    ManagedBy   = "Terraform"
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "testing_site" {
  bucket = aws_s3_bucket.testing_site.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "testing_site" {
  bucket = aws_s3_bucket.testing_site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket public access block (allow public policies for testing)
resource "aws_s3_bucket_public_access_block" "testing_site" {
  bucket = aws_s3_bucket.testing_site.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 bucket website configuration
resource "aws_s3_bucket_website_configuration" "testing_site" {
  bucket = aws_s3_bucket.testing_site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 bucket policy for public read access
resource "aws_s3_bucket_policy" "testing_site" {
  bucket = aws_s3_bucket.testing_site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.testing_site.arn}/*"
      }
    ]
  })
}

# CloudFront distribution for testing site
resource "aws_cloudfront_distribution" "testing_site" {
  origin {
    domain_name = aws_s3_bucket_website_configuration.testing_site.website_endpoint
    origin_id   = "S3-${aws_s3_bucket.testing_site.bucket}"

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
    target_origin_id       = "S3-${aws_s3_bucket.testing_site.bucket}"
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
    Name        = "Robert Consulting Testing Site"
    Environment = "Testing"
    Purpose     = "Testing Site CDN"
    ManagedBy   = "Terraform"
  }
}

# Outputs
output "testing_bucket_name" {
  description = "Name of the testing S3 bucket"
  value       = aws_s3_bucket.testing_site.bucket
}

output "testing_bucket_website_url" {
  description = "Website URL of the testing S3 bucket"
  value       = "http://${aws_s3_bucket.testing_site.bucket}.s3-website-us-east-1.amazonaws.com"
}

output "testing_cloudfront_url" {
  description = "CloudFront URL for the testing site"
  value       = "https://${aws_cloudfront_distribution.testing_site.domain_name}"
}

# Data source for current region is defined in state-management.tf
