#!/bin/bash

# Basic Terraform validation script
# This checks for the most common issues that would cause the automated workflow to fail

echo "🔍 Running basic Terraform validation..."

# Check for reserved environment variables in Lambda
echo "Checking for reserved environment variables..."
if grep -r "AWS_REGION" *.tf; then
    echo "❌ Found AWS_REGION in environment variables (reserved)"
    exit 1
fi

# Check for basic syntax errors
echo "Checking for basic syntax errors..."
for file in *.tf; do
    if [ -f "$file" ]; then
        # Check for unmatched braces
        open_braces=$(grep -o '{' "$file" | wc -l)
        close_braces=$(grep -o '}' "$file" | wc -l)
        if [ "$open_braces" -ne "$close_braces" ]; then
            echo "❌ Unmatched braces in $file"
            exit 1
        fi
        
        # Check for unmatched quotes
        open_quotes=$(grep -o '"' "$file" | wc -l)
        if [ $((open_quotes % 2)) -ne 0 ]; then
            echo "❌ Unmatched quotes in $file"
            exit 1
        fi
    fi
done

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

echo "✅ Basic validation passed"
echo "✅ No syntax errors found"
echo "✅ No duplicate resources found"
echo "✅ No reserved environment variables found"
