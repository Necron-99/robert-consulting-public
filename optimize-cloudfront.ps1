# CloudFront Optimization Script for robert-consulting.net
# This script optimizes CloudFront distributions for cost and performance

Write-Host "🚀 Starting CloudFront optimization..."

# Get the main website distribution ID
$MAIN_DISTRIBUTION_ID = "E36DBYPHUUKB3V"
Write-Host "📊 Main distribution ID: $MAIN_DISTRIBUTION_ID"

# Get current ETag
Write-Host "📋 Getting current ETag..."
$ETAG = aws cloudfront get-distribution-config --id $MAIN_DISTRIBUTION_ID --query "ETag" --output text
Write-Host "🏷️ Current ETag: $ETAG"

# Create optimized configuration
Write-Host "⚙️ Creating optimized configuration..."

$optimizedConfig = @"
{
  "CallerReference": "optimized-$(Get-Date -Format 'yyyyMMddHHmmss')",
  "Comment": "Optimized CloudFront configuration for robert-consulting.net - Cost and Performance Optimized",
  "PriceClass": "PriceClass_100",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-robert-consulting-website",
        "DomainName": "robert-consulting-website.s3-website-us-east-1.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only",
          "OriginSslProtocols": {
            "Quantity": 1,
            "Items": ["TLSv1.2"]
          }
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-robert-consulting-website",
    "ViewerProtocolPolicy": "redirect-to-https",
    "TrustedSigners": {
      "Enabled": false,
      "Quantity": 0
    },
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      },
      "Headers": {
        "Quantity": 0
      }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "Compress": true,
    "SmoothStreaming": false,
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    }
  },
  "CacheBehaviors": {
    "Quantity": 3,
    "Items": [
      {
        "PathPattern": "*.css",
        "TargetOriginId": "S3-robert-consulting-website",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
          "Enabled": false,
          "Quantity": 0
        },
        "ForwardedValues": {
          "QueryString": false,
          "Cookies": {
            "Forward": "none"
          },
          "Headers": {
            "Quantity": 0
          }
        },
        "MinTTL": 0,
        "DefaultTTL": 31536000,
        "MaxTTL": 31536000,
        "Compress": true,
        "SmoothStreaming": false,
        "AllowedMethods": {
          "Quantity": 2,
          "Items": ["GET", "HEAD"],
          "CachedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"]
          }
        }
      },
      {
        "PathPattern": "*.js",
        "TargetOriginId": "S3-robert-consulting-website",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
          "Enabled": false,
          "Quantity": 0
        },
        "ForwardedValues": {
          "QueryString": false,
          "Cookies": {
            "Forward": "none"
          },
          "Headers": {
            "Quantity": 0
          }
        },
        "MinTTL": 0,
        "DefaultTTL": 31536000,
        "MaxTTL": 31536000,
        "Compress": true,
        "SmoothStreaming": false,
        "AllowedMethods": {
          "Quantity": 2,
          "Items": ["GET", "HEAD"],
          "CachedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"]
          }
        }
      },
      {
        "PathPattern": "*.{png,jpg,jpeg,gif,ico,svg,webp}",
        "TargetOriginId": "S3-robert-consulting-website",
        "ViewerProtocolPolicy": "redirect-to-https",
        "TrustedSigners": {
          "Enabled": false,
          "Quantity": 0
        },
        "ForwardedValues": {
          "QueryString": false,
          "Cookies": {
            "Forward": "none"
          },
          "Headers": {
            "Quantity": 0
          }
        },
        "MinTTL": 0,
        "DefaultTTL": 31536000,
        "MaxTTL": 31536000,
        "Compress": true,
        "SmoothStreaming": false,
        "AllowedMethods": {
          "Quantity": 2,
          "Items": ["GET", "HEAD"],
          "CachedMethods": {
            "Quantity": 2,
            "Items": ["GET", "HEAD"]
          }
        }
      }
    ]
  },
  "CustomErrorResponses": {
    "Quantity": 2,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/404.html",
        "ResponseCode": "404",
        "ErrorCachingMinTTL": 300
      },
      {
        "ErrorCode": 403,
        "ResponsePagePath": "/404.html",
        "ResponseCode": "404",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "Logging": {
    "Enabled": false
  },
  "WebACLId": "",
  "HttpVersion": "http2",
  "IsIPV6Enabled": true
}
"@

# Save configuration to file
$optimizedConfig | Out-File -FilePath "optimized-config.json" -Encoding UTF8
Write-Host "📝 Optimized configuration created"

# Apply the configuration update
Write-Host "🔄 Applying optimized configuration..."
try {
    aws cloudfront update-distribution --id $MAIN_DISTRIBUTION_ID --distribution-config file://optimized-config.json --if-match $ETAG
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ CloudFront distribution updated successfully!"
        Write-Host "⏳ Changes are being deployed (this may take 15-20 minutes)"
        Write-Host ""
        Write-Host "🎯 Optimization Summary:"
        Write-Host "  📈 Performance Improvements:"
        Write-Host "    • Static assets (CSS/JS/Images) cached for 1 year"
        Write-Host "    • HTML pages cached for 24 hours"
        Write-Host "    • Compression enabled for all content"
        Write-Host "    • HTTP/2 and IPv6 enabled"
        Write-Host "    • Custom error pages for 404/403"
        Write-Host ""
        Write-Host "  💰 Cost Optimizations:"
        Write-Host "    • PriceClass_100 (US, Canada, Europe only)"
        Write-Host "    • No query string forwarding"
        Write-Host "    • No cookie forwarding"
        Write-Host "    • No custom headers"
        Write-Host "    • Logging disabled"
        Write-Host ""
        Write-Host "  🚀 Cache Behaviors:"
        Write-Host "    • CSS files: 1 year cache"
        Write-Host "    • JS files: 1 year cache"
        Write-Host "    • Images: 1 year cache"
        Write-Host "    • HTML: 24 hours cache"
    } else {
        Write-Host "❌ Failed to update CloudFront distribution"
        Write-Host "💡 This might be due to:"
        Write-Host "   • Distribution is currently being updated"
        Write-Host "   • ETag mismatch (distribution was modified)"
        Write-Host "   • Invalid configuration"
    }
} catch {
    Write-Host "❌ Error applying configuration: $($_.Exception.Message)"
}

# Cleanup
Remove-Item -Path "optimized-config.json" -ErrorAction SilentlyContinue

Write-Host "🏁 CloudFront optimization complete!"

