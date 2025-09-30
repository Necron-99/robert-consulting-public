#!/bin/bash

# AWS Service Health Monitoring Script
# Comprehensive health monitoring for AWS services

set -e

# Configuration
REGION="us-east-1"
S3_BUCKET="robert-consulting-website-2024-bd900b02"
CLOUDFRONT_DISTRIBUTION="E3HUVB85SPZFHO"
WEBSITE_URL="https://robertconsulting.net"

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

# Check S3 service health
check_s3_health() {
    log_info "Checking S3 service health..."
    
    # Check bucket exists and is accessible
    if aws s3api head-bucket --bucket $S3_BUCKET 2>/dev/null; then
        log_success "S3 bucket accessible: $S3_BUCKET"
        S3_STATUS="HEALTHY"
    else
        log_error "S3 bucket not accessible: $S3_BUCKET"
        S3_STATUS="UNHEALTHY"
        return 1
    fi
    
    # Check bucket policy
    if aws s3api get-bucket-policy --bucket $S3_BUCKET &>/dev/null; then
        log_success "S3 bucket policy configured"
    else
        log_warning "S3 bucket policy not found"
    fi
    
    # Check website configuration
    if aws s3api get-bucket-website --bucket $S3_BUCKET &>/dev/null; then
        log_success "S3 website configuration found"
    else
        log_warning "S3 website configuration not found"
    fi
    
    # Get S3 metrics
    S3_OBJECTS=$(aws s3api list-objects-v2 --bucket $S3_BUCKET --query 'KeyCount' --output text 2>/dev/null || echo "0")
    S3_SIZE=$(aws s3api list-objects-v2 --bucket $S3_BUCKET --query 'Contents[].Size' --output text | awk '{sum+=$1} END {print sum/1024/1024 " MB"}' 2>/dev/null || echo "0 MB")
    
    log_success "S3 health check completed"
}

# Check CloudFront service health
check_cloudfront_health() {
    log_info "Checking CloudFront service health..."
    
    # Check distribution exists and is deployed
    DISTRIBUTION_STATUS=$(aws cloudfront get-distribution --id $CLOUDFRONT_DISTRIBUTION --query 'Distribution.Status' --output text 2>/dev/null || echo "NOT_FOUND")
    
    if [ "$DISTRIBUTION_STATUS" = "Deployed" ]; then
        log_success "CloudFront distribution deployed: $CLOUDFRONT_DISTRIBUTION"
        CLOUDFRONT_STATUS="HEALTHY"
    elif [ "$DISTRIBUTION_STATUS" = "InProgress" ]; then
        log_warning "CloudFront distribution in progress: $CLOUDFRONT_DISTRIBUTION"
        CLOUDFRONT_STATUS="DEPLOYING"
    else
        log_error "CloudFront distribution not found or not deployed: $CLOUDFRONT_DISTRIBUTION"
        CLOUDFRONT_STATUS="UNHEALTHY"
        return 1
    fi
    
    # Get CloudFront metrics
    CLOUDFRONT_REQUESTS=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/CloudFront \
        --metric-name Requests \
        --dimensions Name=DistributionId,Value=$CLOUDFRONT_DISTRIBUTION \
        --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 3600 \
        --statistics Sum \
        --query 'Datapoints[0].Sum' \
        --output text 2>/dev/null || echo "0")
    
    CLOUDFRONT_ERROR_RATE=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/CloudFront \
        --metric-name 5xxErrorRate \
        --dimensions Name=DistributionId,Value=$CLOUDFRONT_DISTRIBUTION \
        --start-time $(date -d '1 hour ago' -u +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 3600 \
        --statistics Average \
        --query 'Datapoints[0].Average' \
        --output text 2>/dev/null || echo "0")
    
    log_success "CloudFront health check completed"
}

# Check website accessibility
check_website_health() {
    log_info "Checking website accessibility..."
    
    # Check if website is accessible
    if curl -s -o /dev/null -w "%{http_code}" $WEBSITE_URL | grep -q "200"; then
        log_success "Website accessible: $WEBSITE_URL"
        WEBSITE_STATUS="HEALTHY"
    else
        log_error "Website not accessible: $WEBSITE_URL"
        WEBSITE_STATUS="UNHEALTHY"
        return 1
    fi
    
    # Check response time
    RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" $WEBSITE_URL 2>/dev/null || echo "0")
    
    if (( $(echo "$RESPONSE_TIME < 2.0" | bc -l) )); then
        log_success "Website response time: ${RESPONSE_TIME}s (Good)"
    elif (( $(echo "$RESPONSE_TIME < 5.0" | bc -l) )); then
        log_warning "Website response time: ${RESPONSE_TIME}s (Acceptable)"
    else
        log_error "Website response time: ${RESPONSE_TIME}s (Slow)"
    fi
    
    log_success "Website health check completed"
}

# Check Route53 health
check_route53_health() {
    log_info "Checking Route53 health..."
    
    # Check if domain resolves
    if nslookup robertconsulting.net &>/dev/null; then
        log_success "Domain resolves: robertconsulting.net"
        ROUTE53_STATUS="HEALTHY"
    else
        log_error "Domain does not resolve: robertconsulting.net"
        ROUTE53_STATUS="UNHEALTHY"
        return 1
    fi
    
    # Check DNS propagation
    if dig +short robertconsulting.net &>/dev/null; then
        log_success "DNS records found"
    else
        log_warning "DNS records not found"
    fi
    
    log_success "Route53 health check completed"
}

# Generate health report
generate_health_report() {
    log_info "Generating health report..."
    
    cat > health-report.md << EOF
# AWS Service Health Report

**Date:** $(date)
**Region:** $REGION

## 🏥 Service Health Status

| Service | Status | Details |
|---------|--------|---------|
| **S3** | $S3_STATUS | Bucket: $S3_BUCKET |
| **CloudFront** | $CLOUDFRONT_STATUS | Distribution: $CLOUDFRONT_DISTRIBUTION |
| **Website** | $WEBSITE_STATUS | URL: $WEBSITE_URL |
| **Route53** | $ROUTE53_STATUS | Domain: robertconsulting.net |

## 📊 Service Metrics

| Service | Metric | Value |
|---------|--------|-------|
| **S3** | Objects | $S3_OBJECTS |
| **S3** | Storage | $S3_SIZE |
| **CloudFront** | Requests (1h) | $CLOUDFRONT_REQUESTS |
| **CloudFront** | Error Rate (1h) | $(echo "scale=2; $CLOUDFRONT_ERROR_RATE * 100" | bc -l)% |
| **Website** | Response Time | ${RESPONSE_TIME}s |

## 🚨 Health Alerts

$([ "$S3_STATUS" = "UNHEALTHY" ] && echo "🔴 **S3**: Service unhealthy" || echo "✅ **S3**: Service healthy")
$([ "$CLOUDFRONT_STATUS" = "UNHEALTHY" ] && echo "🔴 **CloudFront**: Service unhealthy" || echo "✅ **CloudFront**: Service healthy")
$([ "$WEBSITE_STATUS" = "UNHEALTHY" ] && echo "🔴 **Website**: Service unhealthy" || echo "✅ **Website**: Service healthy")
$([ "$ROUTE53_STATUS" = "UNHEALTHY" ] && echo "🔴 **Route53**: Service unhealthy" || echo "✅ **Route53**: Service healthy")

## 💡 Recommendations

$([ "$S3_STATUS" = "UNHEALTHY" ] && echo "- Check S3 bucket permissions and configuration" || echo "- S3 service is healthy")
$([ "$CLOUDFRONT_STATUS" = "UNHEALTHY" ] && echo "- Check CloudFront distribution status" || echo "- CloudFront service is healthy")
$([ "$WEBSITE_STATUS" = "UNHEALTHY" ] && echo "- Check website configuration and accessibility" || echo "- Website is healthy")
$([ "$ROUTE53_STATUS" = "UNHEALTHY" ] && echo "- Check DNS configuration and propagation" || echo "- Route53 service is healthy")

---
*Automated health monitoring report*
EOF
    
    log_success "Health report generated: health-report.md"
}

# Send health alerts
send_health_alerts() {
    local unhealthy_services=()
    
    [ "$S3_STATUS" = "UNHEALTHY" ] && unhealthy_services+=("S3")
    [ "$CLOUDFRONT_STATUS" = "UNHEALTHY" ] && unhealthy_services+=("CloudFront")
    [ "$WEBSITE_STATUS" = "UNHEALTHY" ] && unhealthy_services+=("Website")
    [ "$ROUTE53_STATUS" = "UNHEALTHY" ] && unhealthy_services+=("Route53")
    
    if [ ${#unhealthy_services[@]} -gt 0 ]; then
        log_error "Unhealthy services detected: ${unhealthy_services[*]}"
        # Here you would integrate with your alerting system
        # Examples: SNS, Slack, email, etc.
        return 1
    else
        log_success "All services healthy"
        return 0
    fi
}

# Display health summary
display_health_summary() {
    echo ""
    echo "🏥 AWS Service Health Summary"
    echo "============================="
    echo "S3 Status: $S3_STATUS"
    echo "CloudFront Status: $CLOUDFRONT_STATUS"
    echo "Website Status: $WEBSITE_STATUS"
    echo "Route53 Status: $ROUTE53_STATUS"
    echo ""
    echo "📊 Service Metrics"
    echo "=================="
    echo "S3 Objects: $S3_OBJECTS"
    echo "S3 Storage: $S3_SIZE"
    echo "CloudFront Requests (1h): $CLOUDFRONT_REQUESTS"
    echo "CloudFront Error Rate (1h): $(echo "scale=2; $CLOUDFRONT_ERROR_RATE * 100" | bc -l)%"
    echo "Website Response Time: ${RESPONSE_TIME}s"
    echo ""
    
    local unhealthy_count=0
    [ "$S3_STATUS" = "UNHEALTHY" ] && ((unhealthy_count++))
    [ "$CLOUDFRONT_STATUS" = "UNHEALTHY" ] && ((unhealthy_count++))
    [ "$WEBSITE_STATUS" = "UNHEALTHY" ] && ((unhealthy_count++))
    [ "$ROUTE53_STATUS" = "UNHEALTHY" ] && ((unhealthy_count++))
    
    if [ $unhealthy_count -eq 0 ]; then
        log_success "All services healthy!"
    else
        log_error "$unhealthy_count service(s) unhealthy!"
    fi
}

# Main health monitoring function
main() {
    log_info "Starting AWS service health monitoring..."
    
    check_aws_cli
    check_s3_health
    check_cloudfront_health
    check_website_health
    check_route53_health
    
    generate_health_report
    send_health_alerts
    status=$?
    display_health_summary
    
    exit $status
}

# Run main function
main "$@"
