#!/bin/bash

# Lambda Runtime Rollback Script
# Rollback contact-form-api from Node.js 20 to Node.js 18 (if needed)

set -e

echo "🔄 Lambda Runtime Rollback Script"
echo "================================="

# Function to rollback to Node.js 18
rollback_runtime() {
    echo "🔄 Rolling back Lambda function runtime to Node.js 18..."
    
    aws lambda update-function-configuration \
        --function-name contact-form-api \
        --runtime nodejs18.x \
        --region us-east-1
    
    if [ $? -eq 0 ]; then
        echo "✅ Runtime rolled back successfully to Node.js 18"
    else
        echo "❌ Failed to rollback runtime"
        exit 1
    fi
}

# Function to verify the rollback
verify_rollback() {
    echo "🔍 Verifying runtime rollback..."
    
    RUNTIME=$(aws lambda get-function-configuration \
        --function-name contact-form-api \
        --region us-east-1 \
        --query 'Runtime' \
        --output text)
    
    if [ "$RUNTIME" = "nodejs18.x" ]; then
        echo "✅ Runtime successfully rolled back to: $RUNTIME"
    else
        echo "❌ Runtime rollback failed. Current runtime: $RUNTIME"
        exit 1
    fi
}

# Main execution
main() {
    echo "⚠️  WARNING: This will rollback to Node.js 18 (deprecated)"
    echo "This should only be used if there are critical issues with Node.js 20"
    echo ""
    read -p "Are you sure you want to rollback? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rollback_runtime
        verify_rollback
        echo "🔄 Rollback completed successfully!"
    else
        echo "❌ Rollback cancelled"
        exit 0
    fi
}

# Run main function
main "$@"
