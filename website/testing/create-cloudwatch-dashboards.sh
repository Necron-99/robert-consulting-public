#!/bin/bash

# Create CloudWatch Dashboards using AWS CLI
# Alternative to Terraform for creating monitoring dashboards

set -e

# Configuration
REGION="us-east-1"
ACCOUNT_ID="[REDACTED]"

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

# Check AWS CLI and credentials
check_aws_cli() {
    log_info "Checking AWS CLI configuration..."
    
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured. Please run 'aws configure'."
        exit 1
    fi
    
    log_success "AWS CLI configured successfully"
}

# Create Cost Monitoring Dashboard
create_cost_dashboard() {
    log_info "Creating cost monitoring dashboard..."
    
    cat > cost-dashboard.json << 'EOF'
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Billing", "EstimatedCharges", "Currency", "USD"],
                    [".", ".", ".", "Service", "AmazonS3"],
                    [".", ".", ".", "Service", "AmazonCloudFront"],
                    [".", ".", ".", "Service", "AmazonRoute53"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "AWS Service Costs",
                "period": 86400,
                "stat": "Maximum"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "Total AWS Costs",
                "period": 86400,
                "stat": "Maximum",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 50
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/S3", "BucketSizeBytes", "BucketName", "robert-consulting-website-2024-bd900b02", "StorageType", "StandardStorage"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "S3 Storage Usage",
                "period": 86400,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 8,
            "y": 6,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/S3", "NumberOfObjects", "BucketName", "robert-consulting-website-2024-bd900b02", "StorageType", "AllStorageTypes"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "S3 Object Count",
                "period": 86400,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 16,
            "y": 6,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "Requests", "DistributionId", "E3HUVB85SPZFHO"],
                    [".", "BytesDownloaded", ".", "."],
                    [".", "BytesUploaded", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "CloudFront Usage",
                "period": 3600,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 12,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Billing", "EstimatedCharges", "Currency", "USD", "Service", "AmazonS3"],
                    [".", ".", ".", ".", ".", "AmazonCloudFront"],
                    [".", ".", ".", ".", ".", "AmazonRoute53"]
                ],
                "view": "timeSeries",
                "stacked": true,
                "region": "us-east-1",
                "title": "Cost Breakdown by Service",
                "period": 86400,
                "stat": "Maximum"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 12,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "us-east-1",
                "title": "Current Month Cost",
                "period": 86400,
                "stat": "Maximum"
            }
        }
    ]
}
EOF

    aws cloudwatch put-dashboard \
        --dashboard-name "robert-consulting-cost-monitoring" \
        --dashboard-body file://cost-dashboard.json \
        --region $REGION
    
    rm cost-dashboard.json
    log_success "Cost monitoring dashboard created"
}

# Create Service Status Dashboard
create_service_status_dashboard() {
    log_info "Creating service status dashboard..."
    
    cat > service-status-dashboard.json << 'EOF'
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/S3", "4xxErrors", "BucketName", "robert-consulting-website-2024-bd900b02"],
                    [".", "5xxErrors", ".", "."],
                    [".", "TotalRequestTime", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "S3 Service Health",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "4xxErrorRate", "DistributionId", "E3HUVB85SPZFHO"],
                    [".", "5xxErrorRate", ".", "."],
                    [".", "CacheHitRate", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "CloudFront Service Health",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "Requests", "DistributionId", "E3HUVB85SPZFHO"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "CloudFront Request Volume",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 8,
            "y": 6,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "BytesDownloaded", "DistributionId", "E3HUVB85SPZFHO"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "CloudFront Data Transfer",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 16,
            "y": 6,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "OriginLatency", "DistributionId", "E3HUVB85SPZFHO"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "CloudFront Origin Latency",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 12,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "CacheHitRate", "DistributionId", "E3HUVB85SPZFHO"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "CloudFront Cache Hit Rate",
                "period": 300,
                "stat": "Average",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            }
        }
    ]
}
EOF

    aws cloudwatch put-dashboard \
        --dashboard-name "robert-consulting-service-status" \
        --dashboard-body file://service-status-dashboard.json \
        --region $REGION
    
    rm service-status-dashboard.json
    log_success "Service status dashboard created"
}

# Create Performance Dashboard
create_performance_dashboard() {
    log_info "Creating performance dashboard..."
    
    cat > performance-dashboard.json << 'EOF'
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "OriginLatency", "DistributionId", "E3HUVB85SPZFHO"],
                    [".", "CacheHitRate", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "CloudFront Performance",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "Requests", "DistributionId", "E3HUVB85SPZFHO"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "Request Volume",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 6,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "4xxErrorRate", "DistributionId", "E3HUVB85SPZFHO"],
                    [".", "5xxErrorRate", ".", "."]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "Error Rates",
                "period": 300,
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 8,
            "y": 6,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/CloudFront", "BytesDownloaded", "DistributionId", "E3HUVB85SPZFHO"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "Data Transfer",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "metric",
            "x": 16,
            "y": 6,
            "width": 8,
            "height": 6,
            "properties": {
                "metrics": [
                    ["AWS/S3", "TotalRequestTime", "BucketName", "robert-consulting-website-2024-bd900b02"]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "us-east-1",
                "title": "S3 Response Time",
                "period": 300,
                "stat": "Average"
            }
        }
    ]
}
EOF

    aws cloudwatch put-dashboard \
        --dashboard-name "robert-consulting-performance" \
        --dashboard-body file://performance-dashboard.json \
        --region $REGION
    
    rm performance-dashboard.json
    log_success "Performance dashboard created"
}

# Create Cost Alerts
create_cost_alerts() {
    log_info "Creating cost alerts..."
    
    # High cost alert
    aws cloudwatch put-metric-alarm \
        --alarm-name "robert-consulting-high-cost-alert" \
        --alarm-description "High AWS costs alert" \
        --metric-name "EstimatedCharges" \
        --namespace "AWS/Billing" \
        --statistic "Maximum" \
        --period 86400 \
        --threshold 15.0 \
        --comparison-operator "GreaterThanThreshold" \
        --evaluation-periods 1 \
        --dimensions Name=Currency,Value=USD \
        --region $REGION
    
    # S3 cost alert
    aws cloudwatch put-metric-alarm \
        --alarm-name "robert-consulting-s3-cost-alert" \
        --alarm-description "High S3 costs alert" \
        --metric-name "EstimatedCharges" \
        --namespace "AWS/Billing" \
        --statistic "Maximum" \
        --period 86400 \
        --threshold 5.0 \
        --comparison-operator "GreaterThanThreshold" \
        --evaluation-periods 1 \
        --dimensions Name=Currency,Value=USD Name=Service,Value=AmazonS3 \
        --region $REGION
    
    # CloudFront cost alert
    aws cloudwatch put-metric-alarm \
        --alarm-name "robert-consulting-cloudfront-cost-alert" \
        --alarm-description "High CloudFront costs alert" \
        --metric-name "EstimatedCharges" \
        --namespace "AWS/Billing" \
        --statistic "Maximum" \
        --period 86400 \
        --threshold 5.0 \
        --comparison-operator "GreaterThanThreshold" \
        --evaluation-periods 1 \
        --dimensions Name=Currency,Value=USD Name=Service,Value=AmazonCloudFront \
        --region $REGION
    
    log_success "Cost alerts created"
}

# Create Service Health Alerts
create_health_alerts() {
    log_info "Creating service health alerts..."
    
    # CloudFront error rate alert
    aws cloudwatch put-metric-alarm \
        --alarm-name "robert-consulting-cloudfront-error-rate" \
        --alarm-description "CloudFront 5xx error rate alert" \
        --metric-name "5xxErrorRate" \
        --namespace "AWS/CloudFront" \
        --statistic "Average" \
        --period 300 \
        --threshold 5.0 \
        --comparison-operator "GreaterThanThreshold" \
        --evaluation-periods 2 \
        --dimensions Name=DistributionId,Value=E3HUVB85SPZFHO \
        --region $REGION
    
    # S3 error rate alert
    aws cloudwatch put-metric-alarm \
        --alarm-name "robert-consulting-s3-error-rate" \
        --alarm-description "S3 5xx errors alert" \
        --metric-name "5xxErrors" \
        --namespace "AWS/S3" \
        --statistic "Sum" \
        --period 300 \
        --threshold 10.0 \
        --comparison-operator "GreaterThanThreshold" \
        --evaluation-periods 2 \
        --dimensions Name=BucketName,Value=robert-consulting-website-2024-bd900b02 \
        --region $REGION
    
    log_success "Service health alerts created"
}

# Display dashboard URLs
display_dashboard_urls() {
    log_info "Dashboard URLs:"
    echo ""
    echo "📊 Cost Monitoring Dashboard:"
    echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=robert-consulting-cost-monitoring"
    echo ""
    echo "🏥 Service Status Dashboard:"
    echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=robert-consulting-service-status"
    echo ""
    echo "⚡ Performance Dashboard:"
    echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=robert-consulting-performance"
    echo ""
    echo "🚨 CloudWatch Alarms:"
    echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:"
    echo ""
}

# Main function
main() {
    log_info "Creating AWS CloudWatch dashboards..."
    
    check_aws_cli
    create_cost_dashboard
    create_service_status_dashboard
    create_performance_dashboard
    create_cost_alerts
    create_health_alerts
    display_dashboard_urls
    
    log_success "All CloudWatch dashboards and alerts created successfully!"
}

# Run main function
main "$@"
