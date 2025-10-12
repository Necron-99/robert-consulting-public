#!/bin/bash

# Analyze GitHub Actions IP Addresses from CloudFront Access Logs
# This script extracts IP addresses from CloudFront access logs to identify GitHub Actions ranges

set -e

# Configuration
ACCESS_LOGS_BUCKET="robert-consulting-staging-access-logs"
OUTPUT_FILE="github-actions-ips.txt"
ANALYSIS_FILE="github-actions-analysis.md"

echo "🔍 Analyzing GitHub Actions IP Addresses from CloudFront Access Logs"
echo "=================================================================="

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please configure your AWS CLI."
    exit 1
fi

echo "✅ AWS credentials configured"

# Check if the access logs bucket exists
if ! aws s3 ls "s3://$ACCESS_LOGS_BUCKET" &> /dev/null; then
    echo "❌ Access logs bucket not found: $ACCESS_LOGS_BUCKET"
    echo "   Make sure CloudFront access logging is enabled and has generated logs."
    exit 1
fi

echo "✅ Access logs bucket found: $ACCESS_LOGS_BUCKET"

# Create temporary directory for log files
TEMP_DIR=$(mktemp -d)
echo "📁 Using temporary directory: $TEMP_DIR"

# Download recent access logs (last 7 days)
echo "📥 Downloading recent access logs..."
aws s3 sync "s3://$ACCESS_LOGS_BUCKET/staging-access-logs/" "$TEMP_DIR/" --exclude "*" --include "*.gz" --include "*.log"

if [ ! "$(ls -A $TEMP_DIR)" ]; then
    echo "❌ No access logs found in the bucket."
    echo "   This might mean:"
    echo "   1. CloudFront access logging was just enabled"
    echo "   2. No traffic has hit the staging site yet"
    echo "   3. Logs are in a different location"
    exit 1
fi

echo "✅ Downloaded access logs"

# Extract IP addresses from logs
echo "🔍 Extracting IP addresses from access logs..."
ALL_IPS_FILE="$TEMP_DIR/all_ips.txt"
UNIQUE_IPS_FILE="$TEMP_DIR/unique_ips.txt"

# Process both .gz and .log files
find "$TEMP_DIR" -name "*.gz" -exec zcat {} \; -o -name "*.log" -exec cat {} \; | \
    awk '{print $1}' | \
    grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' | \
    sort > "$ALL_IPS_FILE"

# Get unique IPs with counts
sort "$ALL_IPS_FILE" | uniq -c | sort -nr > "$UNIQUE_IPS_FILE"

echo "✅ Extracted IP addresses"

# Identify potential GitHub Actions IPs
echo "🤖 Identifying potential GitHub Actions IP addresses..."

# Known GitHub Actions IP ranges (for reference)
KNOWN_GITHUB_RANGES=(
    "140.82.112.0/20"
    "185.199.108.0/22"
    "192.30.252.0/22"
    "52.74.223.119/32"
    "52.64.108.95/32"
)

# Function to check if IP is in a CIDR range
check_ip_in_range() {
    local ip=$1
    local cidr=$2
    
    # Simple check for known ranges (this is a basic implementation)
    case $cidr in
        "140.82.112.0/20")
            # 140.82.112.0 to 140.82.127.255
            if [[ $ip =~ ^140\.82\.(11[2-9]|12[0-7])\. ]]; then
                return 0
            fi
            ;;
        "185.199.108.0/22")
            # 185.199.108.0 to 185.199.111.255
            if [[ $ip =~ ^185\.199\.(108|109|110|111)\. ]]; then
                return 0
            fi
            ;;
        "192.30.252.0/22")
            # 192.30.252.0 to 192.30.255.255
            if [[ $ip =~ ^192\.30\.(252|253|254|255)\. ]]; then
                return 0
            fi
            ;;
        "52.74.223.119/32")
            if [[ $ip == "52.74.223.119" ]]; then
                return 0
            fi
            ;;
        "52.64.108.95/32")
            if [[ $ip == "52.64.108.95" ]]; then
                return 0
            fi
            ;;
    esac
    return 1
}

# Analyze IPs and categorize them
GITHUB_IPS_FILE="$TEMP_DIR/github_ips.txt"
OTHER_IPS_FILE="$TEMP_DIR/other_ips.txt"

echo "" > "$GITHUB_IPS_FILE"
echo "" > "$OTHER_IPS_FILE"

while read -r count ip; do
    is_github=false
    
    # Check against known GitHub ranges
    for range in "${KNOWN_GITHUB_RANGES[@]}"; do
        if check_ip_in_range "$ip" "$range"; then
            echo "$count $ip (Known GitHub Actions range: $range)" >> "$GITHUB_IPS_FILE"
            is_github=true
            break
        fi
    done
    
    # Check for patterns that might indicate GitHub Actions
    if [[ $is_github == false ]]; then
        # Check for Azure IP ranges (GitHub Actions often uses Azure)
        if [[ $ip =~ ^52\.(1[6-9][0-9]|2[0-5][0-9])\. ]]; then
            echo "$count $ip (Potential Azure/GitHub Actions - 52.x.x.x range)" >> "$GITHUB_IPS_FILE"
            is_github=true
        elif [[ $ip =~ ^20\.(1[8-9][0-9]|2[0-5][0-9])\. ]]; then
            echo "$count $ip (Potential Azure/GitHub Actions - 20.x.x.x range)" >> "$GITHUB_IPS_FILE"
            is_github=true
        elif [[ $ip =~ ^13\.107\. ]]; then
            echo "$count $ip (Potential Microsoft/GitHub Actions - 13.107.x.x range)" >> "$GITHUB_IPS_FILE"
            is_github=true
        fi
    fi
    
    if [[ $is_github == false ]]; then
        echo "$count $ip" >> "$OTHER_IPS_FILE"
    fi
done < "$UNIQUE_IPS_FILE"

# Generate analysis report
echo "📊 Generating analysis report..."

cat > "$ANALYSIS_FILE" << EOF
# GitHub Actions IP Address Analysis

## Summary
- **Analysis Date**: $(date)
- **Access Logs Bucket**: $ACCESS_LOGS_BUCKET
- **Total Unique IPs**: $(wc -l < "$UNIQUE_IPS_FILE")
- **Potential GitHub Actions IPs**: $(wc -l < "$GITHUB_IPS_FILE")

## Potential GitHub Actions IP Addresses

EOF

if [ -s "$GITHUB_IPS_FILE" ]; then
    echo "### High Confidence (Known Ranges)" >> "$ANALYSIS_FILE"
    grep "Known GitHub Actions range" "$GITHUB_IPS_FILE" >> "$ANALYSIS_FILE" || true
    
    echo "" >> "$ANALYSIS_FILE"
    echo "### Medium Confidence (Azure/Microsoft Ranges)" >> "$ANALYSIS_FILE"
    grep "Potential.*GitHub Actions" "$GITHUB_IPS_FILE" >> "$ANALYSIS_FILE" || true
else
    echo "No potential GitHub Actions IP addresses identified." >> "$ANALYSIS_FILE"
fi

cat >> "$ANALYSIS_FILE" << EOF

## All Unique IP Addresses (with request counts)

EOF

cat "$UNIQUE_IPS_FILE" >> "$ANALYSIS_FILE"

cat >> "$ANALYSIS_FILE" << EOF

## Recommended IP Ranges for WAF

Based on the analysis, consider adding these IP ranges to your staging WAF:

\`\`\`
# Known GitHub Actions ranges (high confidence)
140.82.112.0/20
185.199.108.0/22
192.30.252.0/22
52.74.223.119/32
52.64.108.95/32

# Additional ranges to consider (based on analysis)
EOF

# Extract unique IP ranges for recommendations
if [ -s "$GITHUB_IPS_FILE" ]; then
    grep "Potential.*GitHub Actions" "$GITHUB_IPS_FILE" | \
        awk '{print $2}' | \
        sed 's/\.[0-9]*$//' | \
        sort -u | \
        while read -r base_ip; do
            echo "# $base_ip.0/24  # Based on observed traffic"
        done >> "$ANALYSIS_FILE"
fi

echo "\`\`\`" >> "$ANALYSIS_FILE"

# Clean up temporary files
rm -rf "$TEMP_DIR"

echo "✅ Analysis complete!"
echo ""
echo "📊 Results:"
echo "  - Analysis report: $ANALYSIS_FILE"
echo "  - Total unique IPs: $(wc -l < "$UNIQUE_IPS_FILE")"
echo "  - Potential GitHub Actions IPs: $(wc -l < "$GITHUB_IPS_FILE")"
echo ""
echo "📋 Next steps:"
echo "  1. Review the analysis report: $ANALYSIS_FILE"
echo "  2. Identify the most likely GitHub Actions IP ranges"
echo "  3. Update the staging WAF with proper IP restrictions"
echo "  4. Test that GitHub Actions still works with restrictions"
echo "  5. Remove the temporary unrestricted access"
echo ""
echo "🔍 To view the analysis:"
echo "  cat $ANALYSIS_FILE"
