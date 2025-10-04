#!/bin/bash

# Testing Site Cost Monitoring Script
# Monitor costs and usage for the testing environment

set -e

# Configuration
REGION="us-east-1"
BUDGET_NAME="testing-site-budget"
COST_THRESHOLD=8.00  # Alert if costs exceed $8

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

# Get current month costs
get_current_costs() {
    log_info "Fetching current month costs..."
    
    # Get current month start date
    MONTH_START=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d)
    MONTH_END=$(date +%Y-%m-%d)
    
    # Get costs for testing resources
    COSTS=$(aws ce get-cost-and-usage \
        --time-period Start=$MONTH_START,End=$MONTH_END \
        --granularity MONTHLY \
        --metrics BlendedCost \
        --group-by Type=DIMENSION,Key=SERVICE \
        --query 'ResultsByTime[0].Groups[?contains(Keys[0], `Amazon S3`) || contains(Keys[0], `Amazon CloudFront`)].Metrics.BlendedCost.Amount' \
        --output text)
    
    if [ -z "$COSTS" ]; then
        log_warning "No cost data found for testing resources"
        CURRENT_COST=0.00
    else
        CURRENT_COST=$(echo "$COSTS" | awk '{sum+=$1} END {printf "%.2f", sum}')
    fi
    
    log_info "Current month cost: $${CURRENT_COST}"
}

# Get S3 usage
get_s3_usage() {
    log_info "Checking S3 usage..."
    
    # Find testing bucket
    TESTING_BUCKET=$(aws s3api list-buckets --query 'Buckets[?contains(Name, `robert-consulting-testing`)].Name' --output text | head -1)
    
    if [ -z "$TESTING_BUCKET" ]; then
        log_warning "No testing S3 bucket found"
        return
    fi
    
    # Get bucket size
    BUCKET_SIZE=$(aws s3 ls s3://$TESTING_BUCKET --recursive --human-readable --summarize | grep "Total Size" | awk '{print $3, $4}')
    
    log_info "S3 bucket: $TESTING_BUCKET"
    log_info "Bucket size: $BUCKET_SIZE"
}

# Get CloudFront usage
get_cloudfront_usage() {
    log_info "Checking CloudFront usage..."
    
    # Find testing distribution
    DISTRIBUTION_ID=$(aws cloudfront list-distributions --query 'DistributionList.Items[?Comment==`Testing Site Distribution`].Id' --output text | head -1)
    
    if [ -z "$DISTRIBUTION_ID" ]; then
        log_warning "No testing CloudFront distribution found"
        return
    fi
    
    # Get distribution status
    DISTRIBUTION_STATUS=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.Status' --output text)
    DISTRIBUTION_DOMAIN=$(aws cloudfront get-distribution --id $DISTRIBUTION_ID --query 'Distribution.DomainName' --output text)
    
    log_info "CloudFront distribution: $DISTRIBUTION_ID"
    log_info "Status: $DISTRIBUTION_STATUS"
    log_info "Domain: $DISTRIBUTION_DOMAIN"
}

# Check budget status
check_budget_status() {
    log_info "Checking budget status..."
    
    # Get budget information
    BUDGET_INFO=$(aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text) --query "Budgets[?BudgetName=='$BUDGET_NAME']" --output json)
    
    if [ "$BUDGET_INFO" = "[]" ]; then
        log_warning "Budget '$BUDGET_NAME' not found"
        return
    fi
    
    # Get budget limit
    BUDGET_LIMIT=$(echo "$BUDGET_INFO" | jq -r '.[0].BudgetLimit.Amount')
    
    log_info "Budget limit: $${BUDGET_LIMIT}"
    log_info "Current cost: $${CURRENT_COST}"
    
    # Calculate percentage
    PERCENTAGE=$(echo "scale=2; $CURRENT_COST * 100 / $BUDGET_LIMIT" | bc)
    
    if (( $(echo "$CURRENT_COST > $COST_THRESHOLD" | bc -l) )); then
        log_warning "Cost threshold exceeded: $${CURRENT_COST} > $${COST_THRESHOLD}"
    fi
    
    if (( $(echo "$PERCENTAGE > 80" | bc -l) )); then
        log_warning "Budget usage high: ${PERCENTAGE}%"
    fi
}

# Generate cost report
generate_cost_report() {
    log_info "Generating cost report..."
    
    echo ""
    echo "📊 Testing Site Cost Report"
    echo "=========================="
    echo "Date: $(date)"
    echo "Month: $(date +%Y-%m)"
    echo ""
    echo "💰 Cost Summary:"
    echo "  Current Month Cost: $${CURRENT_COST}"
    echo "  Budget Limit: $${BUDGET_LIMIT:-10.00}"
    echo "  Usage Percentage: ${PERCENTAGE:-0}%"
    echo ""
    echo "📈 Resource Usage:"
    echo "  S3 Bucket: $TESTING_BUCKET"
    echo "  S3 Size: $BUCKET_SIZE"
    echo "  CloudFront: $DISTRIBUTION_ID"
    echo "  CloudFront Status: $DISTRIBUTION_STATUS"
    echo ""
    echo "⚠️  Alerts:"
    if (( $(echo "$CURRENT_COST > $COST_THRESHOLD" | bc -l) )); then
        echo "  - Cost threshold exceeded"
    fi
    if (( $(echo "$PERCENTAGE > 80" | bc -l) )); then
        echo "  - Budget usage high (${PERCENTAGE}%)"
    fi
    if [ -z "$TESTING_BUCKET" ] || [ -z "$DISTRIBUTION_ID" ]; then
        echo "  - Some resources not found"
    fi
    echo ""
}

# Send cost alert (if configured)
send_cost_alert() {
    if (( $(echo "$CURRENT_COST > $COST_THRESHOLD" | bc -l) )); then
        log_warning "Cost alert: Testing site costs exceeded threshold"
        # In a real implementation, this would send an email or notification
        echo "Cost Alert: Testing site costs ($${CURRENT_COST}) exceeded threshold ($${COST_THRESHOLD})"
    fi
}

# Main monitoring process
main() {
    log_info "Starting cost monitoring for testing site..."
    
    get_current_costs
    get_s3_usage
    get_cloudfront_usage
    check_budget_status
    generate_cost_report
    send_cost_alert
    
    log_success "Cost monitoring completed"
}

# Run main function
main "$@"
