#!/bin/bash

# Generate Route53 import commands
# Checks existing Route53 records and generates import commands

set -e

echo "🔍 Checking Route53 Records for Import"
echo "======================================"
echo ""

ZONE_ID="Z05682173V2H2T5QWU8P0"  # robertconsulting.net
BAILEYLESSONS_ZONE_ID="Z01009052GCOJI1M2TTF7"  # baileylessons.com

echo "📋 Checking robertconsulting.net zone ($ZONE_ID)..."
echo ""

# Root domain A record
if aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" --query "ResourceRecordSets[?Name=='robertconsulting.net.' && Type=='A']" --output text | grep -q "robertconsulting.net"; then
  echo "✅ Found: robertconsulting.net A record"
  echo "   terraform import aws_route53_record.root_domain ${ZONE_ID}_robertconsulting.net_A"
else
  echo "❌ Not found: robertconsulting.net A record"
fi

# Root domain AAAA record
if aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" --query "ResourceRecordSets[?Name=='robertconsulting.net.' && Type=='AAAA']" --output text | grep -q "robertconsulting.net"; then
  echo "✅ Found: robertconsulting.net AAAA record"
  echo "   terraform import aws_route53_record.root_domain_ipv6 ${ZONE_ID}_robertconsulting.net_AAAA"
else
  echo "❌ Not found: robertconsulting.net AAAA record"
fi

# Staging domain A record
if aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID" --query "ResourceRecordSets[?Name=='staging.robertconsulting.net.' && Type=='A']" --output text | grep -q "staging.robertconsulting.net"; then
  echo "✅ Found: staging.robertconsulting.net A record"
  echo "   terraform import aws_route53_record.staging_domain ${ZONE_ID}_staging.robertconsulting.net_A"
else
  echo "❌ Not found: staging.robertconsulting.net A record"
fi

echo ""
echo "📋 Checking baileylessons.com zone ($BAILEYLESSONS_ZONE_ID)..."
echo ""

# Bailey Lessons admin record
if aws route53 list-resource-record-sets --hosted-zone-id "$BAILEYLESSONS_ZONE_ID" --query "ResourceRecordSets[?Name=='admin.baileylessons.com.' && Type=='A']" --output text | grep -q "admin.baileylessons.com"; then
  echo "✅ Found: admin.baileylessons.com A record"
  echo "   terraform import module.baileylessons.aws_route53_record.admin ${BAILEYLESSONS_ZONE_ID}_admin.baileylessons.com_A"
else
  echo "❌ Not found: admin.baileylessons.com A record"
fi

echo ""
echo "💡 Run these commands in the terraform/ directory to import existing records"

