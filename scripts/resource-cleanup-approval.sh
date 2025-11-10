#!/bin/bash

# Resource Cleanup Approval Script
# SAFETY: This script requires explicit approval before deleting ANY resources
# Never deletes resources automatically - all deletions require manual confirmation

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_header "🔒 RESOURCE CLEANUP APPROVAL WORKFLOW"
echo ""
echo -e "${RED}⚠️  WARNING: This script will DELETE AWS resources!${NC}"
echo -e "${RED}⚠️  All deletions require explicit manual approval${NC}"
echo ""

# Check if running in dry-run mode
DRY_RUN=${DRY_RUN:-true}
if [ "$DRY_RUN" = "true" ]; then
    print_warning "Running in DRY-RUN mode. No resources will be deleted."
    echo ""
fi

# Query DynamoDB for unused resources
print_header "📊 Querying Resource Catalog"

CATALOG_TABLE="robert-consulting-resource-catalog"

# Get unused resources
echo "Querying for unused resources..."
UNUSED_RESOURCES=$(aws dynamodb query \
    --table-name "$CATALOG_TABLE" \
    --index-name "status-index" \
    --key-condition-expression "status = :status" \
    --expression-attribute-values '{":status":{"S":"unused"}}' \
    --output json 2>/dev/null || echo '{"Items":[]}')

RESOURCE_COUNT=$(echo "$UNUSED_RESOURCES" | jq '.Items | length')

if [ "$RESOURCE_COUNT" -eq 0 ]; then
    print_success "No unused resources found. Nothing to clean up."
    exit 0
fi

print_warning "Found $RESOURCE_COUNT unused resource(s) requiring review:"
echo ""

# Display resources
echo "$UNUSED_RESOURCES" | jq -r '.Items[] | "\(.resource_type.S) - \(.resource_name.S) (\(.resource_arn.S))"' | while read -r resource; do
    echo "  - $resource"
done

echo ""
print_header "🔍 VERIFICATION REQUIRED"

echo "Before proceeding, please verify:"
echo "  1. Each resource is truly unused"
echo "  2. No dependencies exist"
echo "  3. Backups are available if needed"
echo ""

# Require explicit confirmation
read -p "Type 'DELETE' (all caps) to proceed with deletion: " confirmation

if [ "$confirmation" != "DELETE" ]; then
    print_error "Deletion cancelled. No resources were deleted."
    exit 1
fi

# Second confirmation
echo ""
read -p "Are you absolutely sure? Type 'YES' (all caps) to confirm: " second_confirmation

if [ "$second_confirmation" != "YES" ]; then
    print_error "Deletion cancelled. No resources were deleted."
    exit 1
fi

# Final safety check - require resource ARN list
echo ""
print_error "FINAL SAFETY CHECK:"
echo "Please provide a comma-separated list of resource ARNs to delete."
echo "This ensures you've reviewed each resource individually."
read -p "Resource ARNs to delete: " arn_list

if [ -z "$arn_list" ]; then
    print_error "No ARNs provided. Deletion cancelled."
    exit 1
fi

# Parse ARNs and delete (if not dry-run)
if [ "$DRY_RUN" = "true" ]; then
    print_warning "DRY-RUN: Would delete the following resources:"
    echo "$arn_list" | tr ',' '\n' | while read -r arn; do
        echo "  - $arn"
    done
    print_success "DRY-RUN complete. No resources were actually deleted."
else
    print_header "🗑️  DELETING RESOURCES"
    
    echo "$arn_list" | tr ',' '\n' | while read -r arn; do
        arn=$(echo "$arn" | xargs) # Trim whitespace
        
        # Extract resource type and name
        resource_type=$(echo "$arn" | cut -d: -f2)
        resource_name=$(echo "$arn" | awk -F'/' '{print $NF}')
        
        print_warning "Deleting: $resource_name ($resource_type)"
        
        # Delete based on resource type
        case "$resource_type" in
            "s3")
                # S3 bucket deletion requires emptying first
                print_warning "  Emptying bucket before deletion..."
                aws s3 rm "s3://$resource_name" --recursive || true
                aws s3api delete-bucket --bucket "$resource_name" || print_error "Failed to delete bucket"
                ;;
            "cloudfront")
                # CloudFront requires disabling first
                dist_id=$(echo "$arn" | awk -F'/' '{print $NF}')
                print_warning "  Disabling distribution before deletion..."
                aws cloudfront get-distribution-config --id "$dist_id" > /tmp/dist-config.json
                # Disable and update, then delete (complex - may need manual intervention)
                print_error "CloudFront deletion requires manual steps. Skipping."
                ;;
            "lambda")
                func_name=$(echo "$arn" | awk -F':' '{print $NF}')
                aws lambda delete-function --function-name "$func_name" || print_error "Failed to delete function"
                ;;
            *)
                print_warning "  Unknown resource type. Manual deletion required."
                ;;
        esac
        
        # Update catalog
        aws dynamodb update-item \
            --table-name "$CATALOG_TABLE" \
            --key "{\"resource_arn\":{\"S\":\"$arn\"}}" \
            --update-expression "SET #status = :status, deleted_at = :deleted" \
            --expression-attribute-names '{"#status":"status"}' \
            --expression-attribute-values '{":status":{"S":"deleted"},":deleted":{"S":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}}' || true
    done
    
    print_success "Deletion process completed."
fi

print_header "✅ CLEANUP COMPLETE"

