#!/bin/bash

# Testing Site Deployment Script
# Cost-optimized deployment for private testing environment

set -e

# Configuration
TESTING_BUCKET="robert-consulting-testing-site"
REGION="us-east-1"
DISTRIBUTION_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

# Create S3 bucket for testing site
create_testing_bucket() {
    log_info "Creating S3 bucket for testing site..."
    
    # Create bucket
    aws s3 mb s3://$TESTING_BUCKET --region $REGION
    
    # Configure bucket for website hosting
    aws s3 website s3://$TESTING_BUCKET --index-document index.html --error-document error.html
    
    # Configure public access block to allow public policies (for testing only)
    aws s3api put-public-access-block --bucket $TESTING_BUCKET \
        --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
    
    # Set bucket policy for public read access (testing only)
    cat > bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$TESTING_BUCKET/*"
        }
    ]
}
EOF
    
    aws s3api put-bucket-policy --bucket $TESTING_BUCKET --policy file://bucket-policy.json
    rm bucket-policy.json
    
    log_success "S3 bucket created: $TESTING_BUCKET"
}

# Run automated tests
run_automated_tests() {
    log_info "Running automated tests..."
    
    # Make test script executable
    chmod +x run-tests.sh
    
    # Run comprehensive tests
    if ./run-tests.sh; then
        log_success "All tests passed"
    else
        log_error "Some tests failed"
        exit 1
    fi
}

# Deploy testing site files
deploy_files() {
    log_info "Deploying testing site files..."
    
    # Sync files to S3
    aws s3 sync . s3://$TESTING_BUCKET --delete
    
    log_success "Files deployed to S3"
}

# Create CloudFront distribution
create_cloudfront_distribution() {
    log_info "Creating CloudFront distribution..."
    
    # Create CloudFront distribution configuration
    cat > cloudfront-config.json << EOF
{
    "CallerReference": "testing-site-$(date +%s)",
    "Comment": "Testing Site Distribution",
    "DefaultRootObject": "index.html",
    "Origins": {
        "Quantity": 1,
        "Items": [
            {
                "Id": "S3-$TESTING_BUCKET",
                "DomainName": "$TESTING_BUCKET.s3-website-$REGION.amazonaws.com",
                "CustomOriginConfig": {
                    "HTTPPort": 80,
                    "HTTPSPort": 443,
                    "OriginProtocolPolicy": "http-only"
                }
            }
        ]
    },
    "DefaultCacheBehavior": {
        "TargetOriginId": "S3-$TESTING_BUCKET",
        "ViewerProtocolPolicy": "redirect-to-https",
        "MinTTL": 0,
        "DefaultTTL": 300,
        "MaxTTL": 3600,
        "Compress": true,
        "ForwardedValues": {
            "QueryString": false,
            "Cookies": {
                "Forward": "none"
            }
        }
    },
    "Enabled": true,
    "PriceClass": "PriceClass_100",
    "CustomErrorResponses": {
        "Quantity": 1,
        "Items": [
            {
                "ErrorCode": 404,
                "ResponseCode": 404,
                "ResponsePagePath": "/error.html"
            }
        ]
    }
}
EOF
    
    # Create distribution
    DISTRIBUTION_ID=$(aws cloudfront create-distribution --distribution-config file://cloudfront-config.json --query 'Distribution.Id' --output text)
    rm cloudfront-config.json
    
    log_success "CloudFront distribution created: $DISTRIBUTION_ID"
}

# Set up cost monitoring
setup_cost_monitoring() {
    log_info "Setting up cost monitoring..."
    
    # Create budget for testing site
    cat > budget-config.json << EOF
{
    "BudgetName": "testing-site-budget",
    "BudgetType": "COST",
    "TimeUnit": "MONTHLY",
    "BudgetLimit": {
        "Amount": "10.00",
        "Unit": "USD"
    },
    "CostFilters": {
        "Tag": [
            "Environment\$testing",
            "Purpose\$private-testing"
        ]
    },
    "NotificationsWithSubscribers": [
        {
            "Notification": {
                "NotificationType": "ACTUAL",
                "ComparisonOperator": "GREATER_THAN",
                "Threshold": 80,
                "ThresholdType": "PERCENTAGE"
            },
            "Subscribers": [
                {
                    "SubscriptionType": "EMAIL",
                    "Address": "your-email@example.com"
                }
            ]
        }
    ]
}
EOF
    
    # Note: Budget creation requires additional permissions
    log_warning "Budget configuration created. Please manually create the budget in AWS Console."
    rm budget-config.json
}

# Display deployment summary
display_summary() {
    log_success "Testing site deployment completed!"
    echo ""
    echo "📊 Deployment Summary:"
    echo "  S3 Bucket: $TESTING_BUCKET"
    echo "  Region: $REGION"
    echo "  CloudFront Distribution: $DISTRIBUTION_ID"
    echo ""
    echo "🌐 Access URLs:"
    echo "  S3 Website: http://$TESTING_BUCKET.s3-website-$REGION.amazonaws.com"
    echo "  CloudFront: https://$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)"
    echo ""
    echo "💰 Cost Estimate:"
    echo "  S3 Storage: ~$0.50/month"
    echo "  CloudFront: ~$1.00/month"
    echo "  Total: ~$1.50/month"
    echo ""
    echo "🔧 Management:"
    echo "  Update files: aws s3 sync . s3://$TESTING_BUCKET"
    echo "  Invalidate cache: aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths '/*'"
    echo "  Delete resources: ./cleanup-testing.sh"
}

# Main deployment process
main() {
    log_info "Starting testing site deployment..."
    
    check_prerequisites
    run_automated_tests
    create_testing_bucket
    deploy_files
    create_cloudfront_distribution
    setup_cost_monitoring
    display_summary
    
    log_success "Testing site deployment completed successfully!"
}

# Run main function
main "$@"
