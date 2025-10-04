#!/bin/bash

# Lambda Runtime Migration Script
# Migrates contact-form-api from Node.js 18 to Node.js 20

set -e

echo "🚀 Starting Lambda Runtime Migration from Node.js 18 to Node.js 20"
echo "================================================================"

# Function to check if AWS CLI is configured
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    echo "✅ AWS CLI is configured"
}

# Function to backup current function configuration
backup_config() {
    echo "📋 Backing up current function configuration..."
    
    aws lambda get-function-configuration \
        --function-name contact-form-api \
        --region us-east-1 > lambda-backup-$(date +%Y%m%d-%H%M%S).json
    
    echo "✅ Configuration backed up"
}

# Function to update function runtime
update_runtime() {
    echo "🔄 Updating Lambda function runtime to Node.js 20..."
    
    aws lambda update-function-configuration \
        --function-name contact-form-api \
        --runtime nodejs20.x \
        --region us-east-1
    
    if [ $? -eq 0 ]; then
        echo "✅ Runtime updated successfully to Node.js 20"
    else
        echo "❌ Failed to update runtime"
        exit 1
    fi
}

# Function to verify the update
verify_update() {
    echo "🔍 Verifying runtime update..."
    
    RUNTIME=$(aws lambda get-function-configuration \
        --function-name contact-form-api \
        --region us-east-1 \
        --query 'Runtime' \
        --output text)
    
    if [ "$RUNTIME" = "nodejs20.x" ]; then
        echo "✅ Runtime successfully updated to: $RUNTIME"
    else
        echo "❌ Runtime update failed. Current runtime: $RUNTIME"
        exit 1
    fi
}

# Function to test the function
test_function() {
    echo "🧪 Testing Lambda function..."
    
    # Create a test payload
    TEST_PAYLOAD='{
        "httpMethod": "POST",
        "body": "{\"name\":\"Test User\",\"email\":\"test@example.com\",\"subject\":\"Test Migration\",\"message\":\"Testing Node.js 20 migration\"}"
    }'
    
    # Invoke the function
    RESPONSE=$(aws lambda invoke \
        --function-name contact-form-api \
        --payload "$TEST_PAYLOAD" \
        --region us-east-1 \
        /tmp/lambda-test-response.json)
    
    if [ $? -eq 0 ]; then
        echo "✅ Lambda function test completed"
        echo "📄 Response saved to /tmp/lambda-test-response.json"
        cat /tmp/lambda-test-response.json
    else
        echo "❌ Lambda function test failed"
        exit 1
    fi
}

# Main execution
main() {
    echo "Starting migration process..."
    
    check_aws_cli
    backup_config
    update_runtime
    verify_update
    test_function
    
    echo ""
    echo "🎉 Migration completed successfully!"
    echo "📊 Summary:"
    echo "   - Runtime: nodejs18.x → nodejs20.x"
    echo "   - Function: contact-form-api"
    echo "   - Status: ✅ Complete"
    echo ""
    echo "📝 Next steps:"
    echo "   1. Monitor function logs for 24-48 hours"
    echo "   2. Test contact form on your website"
    echo "   3. Update any CI/CD pipelines to use Node.js 20"
    echo "   4. Consider updating GitHub Actions workflow"
}

# Run main function
main "$@"
