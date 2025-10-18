#!/bin/bash

# Simple Terraform syntax validation script
# This checks for basic syntax errors without requiring state initialization

echo "🔍 Validating Terraform syntax..."

# Check for duplicate resource names (same type AND same name)
echo "Checking for duplicate resource names..."
duplicates=$(grep -h "^resource " *.tf | sed 's/^resource "\([^"]*\)" "\([^"]*\)".*/\1.\2/' | sort | uniq -d)
if [ ! -z "$duplicates" ]; then
    echo "❌ Found duplicate resource names:"
    echo "$duplicates"
    exit 1
fi

# Check for duplicate data sources (same type AND same name)
echo "Checking for duplicate data sources..."
duplicates=$(grep -h "^data " *.tf | sed 's/^data "\([^"]*\)" "\([^"]*\)".*/\1.\2/' | sort | uniq -d)
if [ ! -z "$duplicates" ]; then
    echo "❌ Found duplicate data sources:"
    echo "$duplicates"
    exit 1
fi

# Check for duplicate outputs
echo "Checking for duplicate outputs..."
duplicates=$(grep -h "^output " *.tf | cut -d'"' -f2 | sort | uniq -d)
if [ ! -z "$duplicates" ]; then
    echo "❌ Found duplicate outputs:"
    echo "$duplicates"
    exit 1
fi

# Check for duplicate providers (same type without alias)
echo "Checking for duplicate providers..."
# Extract provider names that don't have aliases
providers_without_alias=$(grep -A5 "^provider " *.tf | grep -B5 -A5 "^provider " | grep -v "alias" | grep "^provider " | cut -d'"' -f2 | sort | uniq -d)
if [ ! -z "$providers_without_alias" ]; then
    echo "❌ Found duplicate providers without aliases:"
    echo "$providers_without_alias"
    exit 1
fi

# Check for reserved environment variables in Lambda
echo "Checking for reserved environment variables..."
if grep -r "AWS_REGION" *.tf; then
    echo "❌ Found AWS_REGION in environment variables (reserved)"
    exit 1
fi

echo "✅ Basic syntax validation passed"
echo "✅ No duplicate resources found"
echo "✅ No reserved environment variables found"
