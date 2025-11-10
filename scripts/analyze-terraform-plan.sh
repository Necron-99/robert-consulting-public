#!/bin/bash

# Terraform Plan Analyzer
# Analyzes terraform plan output and determines if resources should be created or imported

set -e

echo "🔍 Terraform Plan Analyzer"
echo "=========================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PLAN_FILE="${1:-terraform-plan.txt}"
TERRAFORM_DIR="${2:-terraform}"

if [ ! -f "$PLAN_FILE" ] && [ "$1" != "auto" ]; then
    echo "📝 Generating terraform plan..."
    cd "$TERRAFORM_DIR" || exit 1
    terraform plan -out=tfplan > "../$PLAN_FILE" 2>&1 || {
        echo "⚠️  Plan generation had warnings/errors, but continuing..."
    }
    terraform show -json tfplan > "../${PLAN_FILE%.txt}.json" 2>&1 || true
    cd ..
fi

echo "📋 Analyzing plan file: $PLAN_FILE"
echo ""

# Parse plan for resources to be created
echo -e "${BLUE}🔍 Resources to be CREATED:${NC}"
echo ""

# Resource type patterns and how to check if they exist
check_resource_exists() {
    local resource_type=$1
    local resource_id=$2
    local resource_name=$3
    
    case "$resource_type" in
        aws_s3_bucket)
            aws s3api head-bucket --bucket "$resource_id" 2>/dev/null && echo "EXISTS" || echo "NEW"
            ;;
        aws_cloudfront_distribution)
            aws cloudfront get-distribution --id "$resource_id" 2>/dev/null && echo "EXISTS" || echo "NEW"
            ;;
        aws_lambda_function)
            aws lambda get-function --function-name "$resource_id" 2>/dev/null && echo "EXISTS" || echo "NEW"
            ;;
        aws_route53_record)
            # Route53 records are tricky - check by zone and name
            echo "CHECK_MANUAL"
            ;;
        aws_route53_zone)
            aws route53 get-hosted-zone --id "$resource_id" 2>/dev/null && echo "EXISTS" || echo "NEW"
            ;;
        aws_api_gateway_rest_api)
            aws apigateway get-rest-api --rest-api-id "$resource_id" 2>/dev/null && echo "EXISTS" || echo "NEW"
            ;;
        aws_iam_role)
            aws iam get-role --role-name "$resource_id" 2>/dev/null && echo "EXISTS" || echo "NEW"
            ;;
        aws_dynamodb_table)
            aws dynamodb describe-table --table-name "$resource_id" 2>/dev/null && echo "EXISTS" || echo "NEW"
            ;;
        aws_sns_topic)
            aws sns get-topic-attributes --topic-arn "$resource_id" 2>/dev/null && echo "EXISTS" || echo "NEW"
            ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

# Extract resource information from plan
extract_resources() {
    local plan_file=$1
    
    # Use terraform show -json if available
    if [ -f "${PLAN_FILE%.txt}.json" ]; then
        python3 << 'PYTHON_SCRIPT'
import json
import sys

try:
    with open(sys.argv[1], 'r') as f:
        plan = json.load(f)
    
    resources_to_create = []
    
    if 'planned_values' in plan and 'root_module' in plan['planned_values']:
        def extract_resources(module, prefix=""):
            resources = []
            if 'resources' in module:
                for resource in module['resources']:
                    if resource.get('mode') == 'managed':
                        address = resource.get('address', '')
                        resource_type = resource.get('type', '')
                        resource_name = resource.get('name', '')
                        resources.append({
                            'address': address,
                            'type': resource_type,
                            'name': resource_name,
                            'id': resource.get('values', {}).get('id') or resource.get('values', {}).get('bucket') or resource.get('values', {}).get('name') or resource.get('values', {}).get('function_name') or ''
                        })
            if 'child_modules' in module:
                for child in module['child_modules']:
                    resources.extend(extract_resources(child, prefix))
            return resources
        
        resources_to_create = extract_resources(plan['planned_values']['root_module'])
    
    # Also check resource_changes
    if 'resource_changes' in plan:
        for change in plan['resource_changes']:
            if change.get('change', {}).get('actions', []) == ['create']:
                address = change.get('address', '')
                resource_type = change.get('type', '')
                resource_name = change.get('name', '')
                values = change.get('change', {}).get('after', {})
                resource_id = values.get('id') or values.get('bucket') or values.get('name') or values.get('function_name') or values.get('distribution_id') or ''
                
                # Check if already in list
                if not any(r['address'] == address for r in resources_to_create):
                    resources_to_create.append({
                        'address': address,
                        'type': resource_type,
                        'name': resource_name,
                        'id': resource_id
                    })
    
    # Output in a parseable format
    for resource in resources_to_create:
        print(f"{resource['type']}|{resource['name']}|{resource['address']}|{resource['id']}")
        
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT
        "${PLAN_FILE%.txt}.json"
    else
        # Fallback: parse text output (less reliable)
        grep -E "^\s+# .* will be created" "$plan_file" | sed 's/^[[:space:]]*# //' | sed 's/ will be created$//' || true
    fi
}

IMPORT_COMMANDS_FILE="terraform-import-commands.sh"
echo "#!/bin/bash" > "$IMPORT_COMMANDS_FILE"
echo "# Auto-generated import commands" >> "$IMPORT_COMMANDS_FILE"
echo "# Review before running!" >> "$IMPORT_COMMANDS_FILE"
echo "" >> "$IMPORT_COMMANDS_FILE"
chmod +x "$IMPORT_COMMANDS_FILE"

RESOURCES_TO_IMPORT=()
RESOURCES_TO_CREATE=()
RESOURCES_TO_CHECK=()

# Process each resource
while IFS='|' read -r resource_type resource_name resource_address resource_id; do
    if [ -z "$resource_type" ]; then
        continue
    fi
    
    echo -e "${CYAN}  ${resource_address}${NC}"
    echo -e "    Type: ${resource_type}"
    echo -e "    Name: ${resource_name}"
    if [ -n "$resource_id" ]; then
        echo -e "    ID: ${resource_id}"
    fi
    
    # Check if resource exists
    if [ -n "$resource_id" ]; then
        echo -n "    Status: "
        status=$(check_resource_exists "$resource_type" "$resource_id" "$resource_name")
        
        case "$status" in
            EXISTS)
                echo -e "${YELLOW}EXISTS - Should be IMPORTED${NC}"
                RESOURCES_TO_IMPORT+=("$resource_address|$resource_type|$resource_id")
                
                # Generate import command
                echo "    ${GREEN}→ Import command:${NC}"
                case "$resource_type" in
                    aws_s3_bucket)
                        echo "      terraform import $resource_address $resource_id" >> "$IMPORT_COMMANDS_FILE"
                        echo -e "      ${GREEN}terraform import $resource_address $resource_id${NC}"
                        ;;
                    aws_cloudfront_distribution)
                        echo "      terraform import $resource_address $resource_id" >> "$IMPORT_COMMANDS_FILE"
                        echo -e "      ${GREEN}terraform import $resource_address $resource_id${NC}"
                        ;;
                    aws_lambda_function)
                        echo "      terraform import $resource_address $resource_id" >> "$IMPORT_COMMANDS_FILE"
                        echo -e "      ${GREEN}terraform import $resource_address $resource_id${NC}"
                        ;;
                    aws_route53_zone)
                        echo "      terraform import $resource_address $resource_id" >> "$IMPORT_COMMANDS_FILE"
                        echo -e "      ${GREEN}terraform import $resource_address $resource_id${NC}"
                        ;;
                    *)
                        echo "      # TODO: Determine import ID for $resource_type" >> "$IMPORT_COMMANDS_FILE"
                        echo -e "      ${YELLOW}# Manual import needed for $resource_type${NC}"
                        ;;
                esac
                ;;
            NEW)
                echo -e "${GREEN}NEW - Should be CREATED${NC}"
                RESOURCES_TO_CREATE+=("$resource_address")
                ;;
            CHECK_MANUAL)
                echo -e "${YELLOW}MANUAL CHECK REQUIRED${NC}"
                RESOURCES_TO_CHECK+=("$resource_address|$resource_type")
                ;;
            *)
                echo -e "${YELLOW}UNKNOWN - Manual review needed${NC}"
                RESOURCES_TO_CHECK+=("$resource_address|$resource_type")
                ;;
        esac
    else
        echo -e "    ${YELLOW}Status: Cannot determine - Manual check needed${NC}"
        RESOURCES_TO_CHECK+=("$resource_address|$resource_type")
    fi
    echo ""
done < <(extract_resources "$PLAN_FILE")

# Summary
echo ""
echo "=========================="
echo -e "${BLUE}📊 Summary:${NC}"
echo ""
echo -e "${YELLOW}Resources to IMPORT: ${#RESOURCES_TO_IMPORT[@]}${NC}"
echo -e "${GREEN}Resources to CREATE: ${#RESOURCES_TO_CREATE[@]}${NC}"
echo -e "${CYAN}Resources to CHECK: ${#RESOURCES_TO_CHECK[@]}${NC}"
echo ""

if [ ${#RESOURCES_TO_IMPORT[@]} -gt 0 ]; then
    echo -e "${GREEN}✅ Import commands saved to: $IMPORT_COMMANDS_FILE${NC}"
    echo "   Review and run: bash $IMPORT_COMMANDS_FILE"
    echo ""
fi

if [ ${#RESOURCES_TO_CHECK[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠️  Resources requiring manual review:${NC}"
    for resource in "${RESOURCES_TO_CHECK[@]}"; do
        IFS='|' read -r address type <<< "$resource"
        echo "   - $address ($type)"
    done
    echo ""
fi

echo "💡 Tip: Run 'terraform plan' after imports to verify"

