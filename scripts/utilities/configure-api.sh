#!/bin/bash

# Simple API Configuration Script
# Safely replaces API placeholders with actual values

API_ENDPOINT="$1"
API_KEY="$2"

if [ -z "$API_ENDPOINT" ] || [ -z "$API_KEY" ]; then
    echo "Usage: $0 <api-endpoint> <api-key>"
    exit 1
fi

# Check if api-config.js exists
if [ ! -f "js/api-config.js" ]; then
    echo "Error: js/api-config.js not found"
    exit 1
fi

# Create backup
cp js/api-config.js js/api-config.js.bak

# Use awk for safe replacement (handles special characters better than sed)
awk -v endpoint="$API_ENDPOINT" -v key="$API_KEY" '
{
    gsub(/PLACEHOLDER_API_ENDPOINT/, endpoint)
    gsub(/PLACEHOLDER_API_KEY/, key)
    print
}' js/api-config.js > js/api-config.js.tmp

# Move temp file to original
mv js/api-config.js.tmp js/api-config.js

echo "API configuration updated successfully"
echo "Endpoint: $API_ENDPOINT"
echo "Key: ${API_KEY:0:8}..."
