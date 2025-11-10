#!/bin/bash

# Script to help consolidate duplicate Route53 hosted zones
# WARNING: Review carefully before running!

set -e

echo "🔍 Route53 Zone Consolidation Helper"
echo "====================================="
echo ""
echo -e "${RED}⚠️  WARNING: This script helps identify zones to consolidate.${NC}"
echo -e "${RED}   Review all output carefully before deleting any zones!${NC}"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Zone IDs from the image
ZONE_1="Z05682173V2H2T5QWU8P0"  # 7 records
ZONE_2="Z0219036XF42XEMQOJ4"    # 10 records  
ZONE_3="Z0232243368137F38UDI1"   # 20 records (most records - likely the active one)

echo -e "${BLUE}📊 Analyzing Zones:${NC}"
echo ""

# Check which zone Terraform is using
TERRAFORM_ZONE=""
if [ -f "terraform/terraform.tfstate" ] || terraform state list 2>/dev/null | grep -q "aws_route53_zone.main"; then
  TERRAFORM_ZONE=$(terraform state show aws_route53_zone.main 2>/dev/null | grep "id\s*=" | head -1 | awk '{print $3}' | tr -d '"' || echo "")
  if [ -n "$TERRAFORM_ZONE" ]; then
    echo -e "${GREEN}✅ Terraform is using zone: $TERRAFORM_ZONE${NC}"
  fi
fi

echo ""
echo -e "${BLUE}📋 Zone Analysis:${NC}"
echo ""

# Analyze each zone
declare -A ZONE_RECORDS
declare -A ZONE_NAMESERVERS

for zone_id in "$ZONE_1" "$ZONE_2" "$ZONE_3"; do
  echo -e "${CYAN}Zone: $zone_id${NC}"
  
  # Get name servers
  ns=$(aws route53 get-hosted-zone --id "$zone_id" --query 'DelegationSet.NameServers' --output text 2>/dev/null | tr '\t' ' ' || echo "unknown")
  ZONE_NAMESERVERS["$zone_id"]="$ns"
  echo "  Name Servers: $ns"
  
  # Count and list important records
  records=$(aws route53 list-resource-record-sets --hosted-zone-id "$zone_id" --query 'ResourceRecordSets[?Type==`A` || Type==`AAAA` || Type==`CNAME` || Type==`MX` || Type==`TXT`].{Name:Name,Type:Type}' --output json 2>/dev/null)
  record_count=$(echo "$records" | jq '. | length' 2>/dev/null || echo "0")
  ZONE_RECORDS["$zone_id"]="$record_count"
  echo "  Record Count: $record_count"
  
  # List key record names
  echo "  Key Records:"
  echo "$records" | jq -r '.[] | "    - \(.Name) (\(.Type))"' 2>/dev/null | head -10 || echo "    (Could not list)"
  
  # Check if in Terraform
  if [ "$zone_id" = "$TERRAFORM_ZONE" ]; then
    echo -e "  ${GREEN}✅ In Terraform state${NC}"
  else
    echo -e "  ${YELLOW}⚠️  NOT in Terraform state${NC}"
  fi
  
  echo ""
done

# Determine which zone to keep (usually the one with most records or in Terraform)
KEEP_ZONE=""
if [ -n "$TERRAFORM_ZONE" ]; then
  KEEP_ZONE="$TERRAFORM_ZONE"
  echo -e "${GREEN}✅ Recommended to keep: $KEEP_ZONE (in Terraform)${NC}"
elif [ "${ZONE_RECORDS[$ZONE_3]}" -gt "${ZONE_RECORDS[$ZONE_1]}" ] && [ "${ZONE_RECORDS[$ZONE_3]}" -gt "${ZONE_RECORDS[$ZONE_2]}" ]; then
  KEEP_ZONE="$ZONE_3"
  echo -e "${GREEN}✅ Recommended to keep: $KEEP_ZONE (most records: ${ZONE_RECORDS[$ZONE_3]})${NC}"
else
  echo -e "${YELLOW}⚠️  Could not determine which zone to keep automatically${NC}"
  echo "   Please check your domain registrar's nameservers to find the active zone"
fi

echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo ""
echo "1. Verify which zone is ACTIVE by checking your domain registrar"
echo "2. Export records from duplicate zones (if needed)"
echo "3. Ensure all records are in the zone you're keeping"
echo "4. Update Terraform to use the correct zone ID"
echo "5. Delete duplicate zones (only after verification!)"
echo ""
echo -e "${YELLOW}💡 To export records from a zone:${NC}"
echo "   aws route53 list-resource-record-sets --hosted-zone-id <zone-id> > zone-backup.json"
echo ""
echo -e "${YELLOW}💡 To delete a zone (AFTER verification):${NC}"
echo "   aws route53 delete-hosted-zone --id <zone-id>"
echo "   ${RED}(This is permanent and cannot be undone!)${NC}"

