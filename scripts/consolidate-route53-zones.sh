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

# Zone IDs from AWS console
ZONE_1="Z05682173V2H2T5QWU8P0"  # 7 records
ZONE_2="Z0219036XF42XEMQOJ4"    # 10 records  
ZONE_3="Z0232243368137F38UDI1"   # 20 records

# AWS nameservers for robertconsulting.net (from domain registration)
AWS_NAMESERVERS=(
  "ns-170.awsdns-21.com"
  "ns-1850.awsdns-39.co.uk"
  "ns-874.awsdns-45.net"
  "ns-1359.awsdns-41.org"
)

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
  ns_array=($(aws route53 get-hosted-zone --id "$zone_id" --query 'DelegationSet.NameServers[]' --output text 2>/dev/null || echo ""))
  ns_string=$(IFS=','; echo "${ns_array[*]}")
  ZONE_NAMESERVERS["$zone_id"]="$ns_string"
  echo "  Name Servers: ${ns_array[*]}"
  
  # Check if this zone matches the registered domain's nameservers
  matches_aws=0
  for aws_ns in "${AWS_NAMESERVERS[@]}"; do
    for zone_ns in "${ns_array[@]}"; do
      if [ "$zone_ns" = "$aws_ns" ]; then
        matches_aws=$((matches_aws + 1))
        break
      fi
    done
  done
  
  if [ $matches_aws -eq 4 ]; then
    echo -e "  ${GREEN}✅ MATCHES AWS REGISTRAR NAMESERVERS - THIS IS THE ACTIVE ZONE!${NC}"
    ACTIVE_ZONE="$zone_id"
  elif [ $matches_aws -gt 0 ]; then
    echo -e "  ${YELLOW}⚠️  Partial match ($matches_aws/4 nameservers)${NC}"
  else
    echo -e "  ${RED}❌ Does NOT match AWS registrar nameservers${NC}"
  fi
  
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

# Determine which zone to keep
KEEP_ZONE=""
ACTIVE_ZONE=""

# Priority 1: Zone that matches AWS registrar nameservers
if [ -n "$ACTIVE_ZONE" ]; then
  KEEP_ZONE="$ACTIVE_ZONE"
  echo -e "${GREEN}✅ ACTIVE ZONE IDENTIFIED: $KEEP_ZONE (matches AWS registrar nameservers)${NC}"
# Priority 2: Zone in Terraform state
elif [ -n "$TERRAFORM_ZONE" ]; then
  KEEP_ZONE="$TERRAFORM_ZONE"
  echo -e "${YELLOW}⚠️  Recommended to keep: $KEEP_ZONE (in Terraform, but verify nameservers match)${NC}"
# Priority 3: Zone with most records
elif [ "${ZONE_RECORDS[$ZONE_3]}" -gt "${ZONE_RECORDS[$ZONE_1]}" ] && [ "${ZONE_RECORDS[$ZONE_3]}" -gt "${ZONE_RECORDS[$ZONE_2]}" ]; then
  KEEP_ZONE="$ZONE_3"
  echo -e "${YELLOW}⚠️  Recommended to keep: $KEEP_ZONE (most records: ${ZONE_RECORDS[$ZONE_3]}, but verify nameservers)${NC}"
else
  echo -e "${RED}❌ Could not determine which zone to keep automatically${NC}"
  echo "   Check which zone's nameservers match: ${AWS_NAMESERVERS[*]}"
fi

echo ""
echo -e "${BLUE}📝 Next Steps:${NC}"
echo ""
if [ -n "$ACTIVE_ZONE" ]; then
  echo -e "${GREEN}1. ✅ Active zone identified: $ACTIVE_ZONE${NC}"
  echo "2. Import this zone into Terraform:"
  echo "   cd terraform"
  echo "   terraform import aws_route53_zone.main $ACTIVE_ZONE"
  echo "3. Export records from duplicate zones (backup)"
  echo "4. Verify all important records are in zone $ACTIVE_ZONE"
  echo "5. Delete duplicate zones (AFTER verification!):"
  for zone_id in "$ZONE_1" "$ZONE_2" "$ZONE_3"; do
    if [ "$zone_id" != "$ACTIVE_ZONE" ]; then
      echo "   aws route53 delete-hosted-zone --id $zone_id"
    fi
  done
else
  echo "1. Check which zone's nameservers match AWS registrar:"
  echo "   ${AWS_NAMESERVERS[*]}"
  echo "2. Import that zone into Terraform"
  echo "3. Export records from duplicate zones (backup)"
  echo "4. Verify all records are in the zone you're keeping"
  echo "5. Delete duplicate zones (only after verification!)"
fi
echo ""
echo -e "${YELLOW}💡 To export records from a zone:${NC}"
echo "   aws route53 list-resource-record-sets --hosted-zone-id <zone-id> > zone-backup.json"
echo ""
echo -e "${YELLOW}💡 To delete a zone (AFTER verification):${NC}"
echo "   aws route53 delete-hosted-zone --id <zone-id>"
echo "   ${RED}(This is permanent and cannot be undone!)${NC}"

