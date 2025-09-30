#!/bin/bash

# CloudFront Optimization Script for robert-consulting.net
# This script optimizes CloudFront distributions for cost and performance

echo "🚀 Starting CloudFront optimization..."

# Get the main website distribution ID
MAIN_DISTRIBUTION_ID="E36DBYPHUUKB3V"
echo "📊 Main distribution ID: $MAIN_DISTRIBUTION_ID"

# Get current configuration
echo "📋 Getting current configuration..."
aws cloudfront get-distribution-config --id $MAIN_DISTRIBUTION_ID --output json > current-config.json

# Extract ETag for update
ETAG=$(aws cloudfront get-distribution-config --id $MAIN_DISTRIBUTION_ID --query "ETag" --output text)
echo "🏷️ Current ETag: $ETAG"

# Create optimized configuration
echo "⚙️ Creating optimized configuration..."

# Update the configuration with optimizations
cat > update-config.json << 'EOF'
{
  "CallerReference": "optimized-$(date +%s)",
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
EOF

echo "📝 Optimized configuration created"

# Apply the configuration update
echo "🔄 Applying optimized configuration..."
aws cloudfront update-distribution \
  --id $MAIN_DISTRIBUTION_ID \
  --distribution-config file://update-config.json \
  --if-match $ETAG

if [ $? -eq 0 ]; then
  echo "✅ CloudFront distribution updated successfully!"
  echo "⏳ Changes are being deployed (this may take 15-20 minutes)"
  echo ""
  echo "🎯 Optimization Summary:"
  echo "  📈 Performance Improvements:"
  echo "    • Static assets (CSS/JS/Images) cached for 1 year"
  echo "    • HTML pages cached for 24 hours"
  echo "    • Compression enabled for all content"
  echo "    • HTTP/2 and IPv6 enabled"
  echo "    • Custom error pages for 404/403"
  echo ""
  echo "  💰 Cost Optimizations:"
  echo "    • PriceClass_100 (US, Canada, Europe only)"
  echo "    • No query string forwarding"
  echo "    • No cookie forwarding"
  echo "    • No custom headers"
  echo "    • Logging disabled"
  echo ""
  echo "  🚀 Cache Behaviors:"
  echo "    • CSS files: 1 year cache"
  echo "    • JS files: 1 year cache"
  echo "    • Images: 1 year cache"
  echo "    • HTML: 24 hours cache"
else
  echo "❌ Failed to update CloudFront distribution"
  echo "💡 This might be due to:"
  echo "   • Distribution is currently being updated"
  echo "   • ETag mismatch (distribution was modified)"
  echo "   • Invalid configuration"
fi

# Cleanup
rm -f current-config.json update-config.json

echo "🏁 CloudFront optimization complete!"

