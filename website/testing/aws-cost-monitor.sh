#!/bin/bash

# AWS Cost Monitoring Script
# Comprehensive cost monitoring and alerting for AWS services

set -e

# Configuration
REGION="us-east-1"
BUDGET_LIMIT=10.00
ALERT_THRESHOLD=8.00
CRITICAL_THRESHOLD=9.50

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

# Get current month costs
get_current_costs() {
    log_info "Fetching current month costs..."
    
    # Get total costs
    TOTAL_COST=$(aws ce get-cost-and-usage \
        --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
        --output text 2>/dev/null || echo "0.00")
    
    # Get S3 costs
    S3_COST=$(aws ce get-cost-and-usage \
        --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query 'ResultsByTime[0].Groups[?Keys[0]==`Amazon Simple Storage Service`].Metrics.BlendedCost.Amount' \
        --output text 2>/dev/null || echo "0.00")
    
    # Get CloudFront costs
    CLOUDFRONT_COST=$(aws ce get-cost-and-usage \
        --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query 'ResultsByTime[0].Groups[?Keys[0]==`Amazon CloudFront`].Metrics.BlendedCost.Amount' \
        --output text 2>/dev/null || echo "0.00")
    
    # Get Route53 costs
    ROUTE53_COST=$(aws ce get-cost-and-usage \
        --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query 'ResultsByTime[0].Groups[?Keys[0]==`Amazon Route 53`].Metrics.BlendedCost.Amount' \
        --output text 2>/dev/null || echo "0.00")
    
    log_success "Cost data retrieved successfully"
}

# Check cost thresholds
check_cost_thresholds() {
    log_info "Checking cost thresholds..."
    
    # Convert to float for comparison
    TOTAL_FLOAT=$(echo "$TOTAL_COST" | bc -l)
    ALERT_FLOAT=$(echo "$ALERT_THRESHOLD" | bc -l)
    CRITICAL_FLOAT=$(echo "$CRITICAL_THRESHOLD" | bc -l)
    
    if (( $(echo "$TOTAL_FLOAT > $CRITICAL_FLOAT" | bc -l) )); then
        log_error "CRITICAL: Monthly costs ($TOTAL_COST) exceed critical threshold ($CRITICAL_THRESHOLD)"
        return 2
    elif (( $(echo "$TOTAL_FLOAT > $ALERT_FLOAT" | bc -l) )); then
        log_warning "ALERT: Monthly costs ($TOTAL_COST) exceed alert threshold ($ALERT_THRESHOLD)"
        return 1
    else
        log_success "Costs within acceptable limits ($TOTAL_COST < $ALERT_THRESHOLD)"
        return 0
    fi
}

# Get service usage metrics
get_service_metrics() {
    log_info "Fetching service usage metrics..."
    
    # S3 metrics
    S3_STORAGE=$(aws s3api list-objects-v2 \
        --bucket robert-consulting-website-2024-bd900b02 \
        --query 'Contents[].Size' \
        --output text | awk '{sum+=$1} END {print sum/1024/1024/1024 " GB"}' 2>/dev/null || echo "0 GB")
    
    S3_OBJECTS=$(aws s3api list-objects-v2 \
        --bucket robert-consulting-website-2024-bd900b02 \
        --query 'KeyCount' \
        --output text 2>/dev/null || echo "0")
    
    # CloudFront metrics (last 24 hours)
    CLOUDFRONT_REQUESTS=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/CloudFront \
        --metric-name Requests \
        --dimensions Name=DistributionId,Value=E36DBYPHUUKB3V \
        --start-time $(date -d '24 hours ago' -u +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 86400 \
        --statistics Sum \
        --query 'Datapoints[0].Sum' \
        --output text 2>/dev/null || echo "0")
    
    CLOUDFRONT_BYTES=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/CloudFront \
        --metric-name BytesDownloaded \
        --dimensions Name=DistributionId,Value=E36DBYPHUUKB3V \
        --start-time $(date -d '24 hours ago' -u +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 86400 \
        --statistics Sum \
        --query 'Datapoints[0].Sum' \
        --output text 2>/dev/null || echo "0")
    
    log_success "Service metrics retrieved successfully"
}

# Generate cost report
generate_cost_report() {
    log_info "Generating cost report..."
    
    cat > cost-report.md << EOF
# AWS Cost Monitoring Report

**Date:** $(date)
**Region:** $REGION
**Budget Limit:** \$$BUDGET_LIMIT

## 💰 Cost Summary

| Service | Cost (USD) | Percentage |
|---------|------------|------------|
| **Total** | \$$TOTAL_COST | 100% |
| S3 | \$$S3_COST | $(echo "scale=1; $S3_COST * 100 / $TOTAL_COST" | bc -l)% |
| CloudFront | \$$CLOUDFRONT_COST | $(echo "scale=1; $CLOUDFRONT_COST * 100 / $TOTAL_COST" | bc -l)% |
| Route53 | \$$ROUTE53_COST | $(echo "scale=1; $ROUTE53_COST * 100 / $TOTAL_COST" | bc -l)% |

## 📊 Usage Metrics

| Service | Metric | Value |
|---------|--------|-------|
| **S3** | Storage Used | $S3_STORAGE |
| **S3** | Object Count | $S3_OBJECTS |
| **CloudFront** | Requests (24h) | $CLOUDFRONT_REQUESTS |
| **CloudFront** | Data Transfer (24h) | $(echo "scale=2; $CLOUDFRONT_BYTES / 1024 / 1024 / 1024" | bc -l) GB |

## 🚨 Cost Alerts

$([ $(echo "$TOTAL_COST > $CRITICAL_THRESHOLD" | bc -l) -eq 1 ] && echo "🔴 **CRITICAL**: Costs exceed critical threshold" || echo "✅ Costs within acceptable limits")

## 📈 Cost Trends

- **Current Month**: \$$TOTAL_COST
- **Alert Threshold**: \$$ALERT_THRESHOLD
- **Critical Threshold**: \$$CRITICAL_THRESHOLD
- **Budget Limit**: \$$BUDGET_LIMIT

## 💡 Recommendations

$([ $(echo "$TOTAL_COST > $ALERT_THRESHOLD" | bc -l) -eq 1 ] && echo "- Consider optimizing S3 storage classes" || echo "- Costs are within acceptable limits")
$([ $(echo "$S3_COST > 2.00" | bc -l) -eq 1 ] && echo "- Review S3 storage optimization" || echo "- S3 costs are reasonable")
$([ $(echo "$CLOUDFRONT_COST > 2.00" | bc -l) -eq 1 ] && echo "- Consider CloudFront caching optimization" || echo "- CloudFront costs are reasonable")

---
*Automated cost monitoring report*
EOF
    
    log_success "Cost report generated: cost-report.md"
}

# Send cost alerts
send_cost_alerts() {
    local status=$1
    
    if [ $status -eq 2 ]; then
        log_error "CRITICAL cost alert triggered!"
        # Here you would integrate with your alerting system
        # Examples: SNS, Slack, email, etc.
    elif [ $status -eq 1 ]; then
        log_warning "Cost alert triggered!"
        # Here you would integrate with your alerting system
    fi
}

# Display cost summary
display_cost_summary() {
    echo ""
    echo "💰 AWS Cost Summary"
    echo "==================="
    echo "Total Cost: \$$TOTAL_COST"
    echo "S3 Cost: \$$S3_COST"
    echo "CloudFront Cost: \$$CLOUDFRONT_COST"
    echo "Route53 Cost: \$$ROUTE53_COST"
    echo ""
    echo "📊 Usage Summary"
    echo "================"
    echo "S3 Storage: $S3_STORAGE"
    echo "S3 Objects: $S3_OBJECTS"
    echo "CloudFront Requests (24h): $CLOUDFRONT_REQUESTS"
    echo "CloudFront Data Transfer (24h): $(echo "scale=2; $CLOUDFRONT_BYTES / 1024 / 1024 / 1024" | bc -l) GB"
    echo ""
    
    if [ $status -eq 2 ]; then
        log_error "CRITICAL: Costs exceed critical threshold!"
    elif [ $status -eq 1 ]; then
        log_warning "ALERT: Costs exceed alert threshold!"
    else
        log_success "Costs within acceptable limits"
    fi
}

# Main monitoring function
main() {
    log_info "Starting AWS cost monitoring..."
    
    check_aws_cli
    get_current_costs
    get_service_metrics
    check_cost_thresholds
    status=$?
    
    generate_cost_report
    send_cost_alerts $status
    display_cost_summary
    
    if [ $status -eq 2 ]; then
        exit 2
    elif [ $status -eq 1 ]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function
main "$@"
