#!/bin/bash

# Query Resource Catalog
# Helper script to query the DynamoDB resource catalog

set -e

CATALOG_TABLE="robert-consulting-resource-catalog"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Query by status
query_by_status() {
    local status=$1
    print_header "Resources with status: $status"
    
    aws dynamodb query \
        --table-name "$CATALOG_TABLE" \
        --index-name "status-index" \
        --key-condition-expression "status = :status" \
        --expression-attribute-values "{\":status\":{\"S\":\"$status\"}}" \
        --output json | jq -r '.Items[] | "\(.resource_type.S) - \(.resource_name.S) (\(.resource_arn.S))"'
}

# Query by type
query_by_type() {
    local type=$1
    print_header "Resources of type: $type"
    
    aws dynamodb query \
        --table-name "$CATALOG_TABLE" \
        --index-name "type-index" \
        --key-condition-expression "resource_type = :type" \
        --expression-attribute-values "{\":type\":{\"S\":\"$type\"}}" \
        --output json | jq -r '.Items[] | "\(.resource_name.S) - Status: \(.status.S)"'
}

# Show summary
show_summary() {
    print_header "Resource Catalog Summary"
    
    echo "By Status:"
    for status in active unused needs-tagging needs-attention; do
        count=$(aws dynamodb query \
            --table-name "$CATALOG_TABLE" \
            --index-name "status-index" \
            --key-condition-expression "status = :status" \
            --expression-attribute-values "{\":status\":{\"S\":\"$status\"}}" \
            --select COUNT \
            --output json | jq -r '.Count')
        echo "  $status: $count"
    done
    
    echo ""
    echo "By Type:"
    for type in s3 cloudfront lambda; do
        count=$(aws dynamodb query \
            --table-name "$CATALOG_TABLE" \
            --index-name "type-index" \
            --key-condition-expression "resource_type = :type" \
            --expression-attribute-values "{\":type\":{\"S\":\"$type\"}}" \
            --select COUNT \
            --output json | jq -r '.Count')
        echo "  $type: $count"
    done
}

# Main
case "${1:-summary}" in
    "unused")
        query_by_status "unused"
        ;;
    "needs-tagging")
        query_by_status "needs-tagging"
        ;;
    "active")
        query_by_status "active"
        ;;
    "s3")
        query_by_type "s3"
        ;;
    "cloudfront")
        query_by_type "cloudfront"
        ;;
    "lambda")
        query_by_type "lambda"
        ;;
    "summary"|*)
        show_summary
        ;;
esac

