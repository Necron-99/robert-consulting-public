#!/bin/bash

# Comprehensive Security Scanning Script
# For private repositories that need external security scanning

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_ISSUES=0
CRITICAL_ISSUES=0
HIGH_ISSUES=0
MEDIUM_ISSUES=0
LOW_ISSUES=0

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS")
            echo -e "${GREEN}✅ $message${NC}"
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  $message${NC}"
            ;;
        "ERROR")
            echo -e "${RED}❌ $message${NC}"
            ;;
        "INFO")
            echo -e "${BLUE}ℹ️  $message${NC}"
            ;;
    esac
}

# Function to increment counters
increment_issue() {
    local severity=$1
    TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
    case $severity in
        "CRITICAL")
            CRITICAL_ISSUES=$((CRITICAL_ISSUES + 1))
            ;;
        "HIGH")
            HIGH_ISSUES=$((HIGH_ISSUES + 1))
            ;;
        "MEDIUM")
            MEDIUM_ISSUES=$((MEDIUM_ISSUES + 1))
            ;;
        "LOW")
            LOW_ISSUES=$((LOW_ISSUES + 1))
            ;;
    esac
}

# Function to scan for secrets
scan_secrets() {
    local directory=$1
    local file_pattern=$2
    local severity=${3:-"HIGH"}
    
    print_status "INFO" "Scanning $directory for secrets in $file_pattern files..."
    
    local secrets_found=0
    
    # Check for hardcoded passwords (exclude keywords, meta tags, and legitimate content)
    if find "$directory" -name "$file_pattern" -type f 2>/dev/null | xargs grep -l -E "password\s*=\s*[\"'][^\"']{4,}[\"']" 2>/dev/null | grep -v "placeholder\|example\|test\|keywords\|meta.*content\|description\|title"; then
        print_status "ERROR" "Hardcoded passwords found in $directory"
        increment_issue "$severity"
        secrets_found=$((secrets_found + 1))
    fi
    
    # Check for API keys (exclude keywords and meta tags)
    if find "$directory" -name "$file_pattern" -type f 2>/dev/null | xargs grep -l -E "api.*key\s*=\s*[\"'][^\"']{8,}[\"']" 2>/dev/null | grep -v "keywords\|meta.*content\|description\|title"; then
        print_status "ERROR" "Hardcoded API keys found in $directory"
        increment_issue "$severity"
        secrets_found=$((secrets_found + 1))
    fi
    
    # Check for tokens (exclude keywords and meta tags)
    if find "$directory" -name "$file_pattern" -type f 2>/dev/null | xargs grep -l -E "token\s*=\s*[\"'][^\"']{8,}[\"']" 2>/dev/null | grep -v "placeholder\|example\|test\|keywords\|meta.*content\|description\|title"; then
        print_status "ERROR" "Hardcoded tokens found in $directory"
        increment_issue "$severity"
        secrets_found=$((secrets_found + 1))
    fi
    
    # Check for AWS credentials
    if find "$directory" -name "$file_pattern" -type f 2>/dev/null | xargs grep -l -E "(aws_access_key|aws_secret_key)\s*=\s*[\"'][^\"']{8,}[\"']" 2>/dev/null; then
        print_status "ERROR" "Hardcoded AWS credentials found in $directory"
        increment_issue "$severity"
        secrets_found=$((secrets_found + 1))
    fi
    
    if [ $secrets_found -eq 0 ]; then
        print_status "SUCCESS" "No secrets found in $directory"
    fi
}

# Function to scan Terraform files
scan_terraform() {
    print_status "INFO" "Scanning Terraform files for security issues..."
    
    local terraform_issues=0
    
    # Check for hardcoded credentials
    if grep -r -E "aws_access_key\s*=\s*[\"'][^\"']{8,}[\"']" terraform/ --include="*.tf" 2>/dev/null; then
        print_status "ERROR" "Hardcoded AWS access keys in Terraform files"
        increment_issue "CRITICAL"
        terraform_issues=$((terraform_issues + 1))
    fi
    
    if grep -r -E "aws_secret_key\s*=\s*[\"'][^\"']{8,}[\"']" terraform/ --include="*.tf" 2>/dev/null; then
        print_status "ERROR" "Hardcoded AWS secret keys in Terraform files"
        increment_issue "CRITICAL"
        terraform_issues=$((terraform_issues + 1))
    fi
    
    # Check for sensitive data marked as non-sensitive
    if grep -r -E "sensitive\s*=\s*false" terraform/ --include="*.tf" 2>/dev/null; then
        print_status "WARNING" "Sensitive variables marked as non-sensitive in Terraform"
        increment_issue "MEDIUM"
        terraform_issues=$((terraform_issues + 1))
    fi
    
    # Check for hardcoded passwords
    if grep -r -E "password\s*=\s*[\"'][^\"']{4,}[\"']" terraform/ --include="*.tf" 2>/dev/null | grep -v "default.*=.*\""; then
        print_status "ERROR" "Hardcoded passwords in Terraform files"
        increment_issue "HIGH"
        terraform_issues=$((terraform_issues + 1))
    fi
    
    if [ $terraform_issues -eq 0 ]; then
        print_status "SUCCESS" "No security issues found in Terraform files"
    fi
}

# Function to scan Lambda functions
scan_lambda() {
    print_status "INFO" "Scanning Lambda functions for security issues..."
    
    local lambda_issues=0
    
    # Check for hardcoded credentials
    if find lambda/ -name "*.js" -o -name "*.py" -o -name "*.ts" 2>/dev/null | xargs grep -l -E "(aws_access_key|aws_secret_key|password|token)\s*=\s*[\"'][^\"']{8,}[\"']" 2>/dev/null; then
        print_status "ERROR" "Hardcoded credentials in Lambda functions"
        increment_issue "HIGH"
        lambda_issues=$((lambda_issues + 1))
    fi
    
    # Check for sensitive data logging
    if find lambda/ -name "*.js" 2>/dev/null | xargs grep -l "console\.log.*password\|console\.log.*token\|console\.log.*key" 2>/dev/null; then
        print_status "WARNING" "Potential sensitive data logging in Lambda functions"
        increment_issue "MEDIUM"
        lambda_issues=$((lambda_issues + 1))
    fi
    
    if [ $lambda_issues -eq 0 ]; then
        print_status "SUCCESS" "No security issues found in Lambda functions"
    fi
}

# Function to scan shell scripts
scan_scripts() {
    print_status "INFO" "Scanning shell scripts for security issues..."
    
    local script_issues=0
    
    # Check for hardcoded secrets (exclude legitimate keyword usage)
    if grep -r -E "password\s*=\s*[\"'][^\"']{4,}[\"']" scripts/ --include="*.sh" --include="*.ps1" 2>/dev/null | grep -v "echo.*password\|keywords\|get_weekday_keywords"; then
        print_status "ERROR" "Hardcoded passwords in scripts"
        increment_issue "HIGH"
        script_issues=$((script_issues + 1))
    fi
    
    if grep -r -E "api.*key\s*=\s*[\"'][^\"']{8,}[\"']" scripts/ --include="*.sh" --include="*.ps1" 2>/dev/null | grep -v "keywords\|get_weekday_keywords"; then
        print_status "ERROR" "Hardcoded API keys in scripts"
        increment_issue "HIGH"
        script_issues=$((script_issues + 1))
    fi
    
    # Check for dangerous commands
    if grep -r -E "(rm\s+-rf\s+/|chmod\s+777|chown\s+-R\s+root)" scripts/ --include="*.sh" 2>/dev/null; then
        print_status "WARNING" "Potentially dangerous commands found in scripts"
        increment_issue "MEDIUM"
        script_issues=$((script_issues + 1))
    fi
    
    if [ $script_issues -eq 0 ]; then
        print_status "SUCCESS" "No security issues found in scripts"
    fi
}

# Function to scan configuration files
scan_configs() {
    print_status "INFO" "Scanning configuration files for security issues..."
    
    local config_issues=0
    
    # Check for hardcoded credentials in JSON files (exclude meta tags and keywords)
    if grep -r -E "(password|token|key|secret)\s*:\s*[\"'][^\"']{4,}[\"']" . --include="*.json" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null | grep -v "placeholder\|example\|test\|keywords\|meta.*content\|description\|title"; then
        print_status "ERROR" "Hardcoded credentials in configuration files"
        increment_issue "HIGH"
        config_issues=$((config_issues + 1))
    fi
    
    # Check for AWS account IDs
    if grep -r -E "account.*id\s*:\s*[\"'][0-9]{12}[\"']" . --include="*.json" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null; then
        print_status "WARNING" "Hardcoded AWS account IDs in configuration files"
        increment_issue "LOW"
        config_issues=$((config_issues + 1))
    fi
    
    if [ $config_issues -eq 0 ]; then
        print_status "SUCCESS" "No security issues found in configuration files"
    fi
}

# Function to scan for security headers
scan_security_headers() {
    print_status "INFO" "Scanning for security headers in HTML files..."
    
    local header_issues=0
    
    # Check for missing CSP headers
    if find . -name "*.html" -type f 2>/dev/null | xargs grep -L "Content-Security-Policy" 2>/dev/null; then
        print_status "WARNING" "Missing Content-Security-Policy headers in HTML files"
        increment_issue "MEDIUM"
        header_issues=$((header_issues + 1))
    fi
    
    if [ $header_issues -eq 0 ]; then
        print_status "SUCCESS" "Security headers present in HTML files"
    fi
}

# Function to scan for HTTP links
scan_http_links() {
    print_status "INFO" "Scanning for HTTP links (should use HTTPS)..."
    
    local http_links=0
    
    # Check for HTTP links in HTML and JS files
    if grep -r "http://" . --include="*.html" --include="*.js" 2>/dev/null | grep -v "localhost" | grep -v "127.0.0.1"; then
        print_status "WARNING" "HTTP links found (should use HTTPS)"
        increment_issue "LOW"
        http_links=$((http_links + 1))
    fi
    
    if [ $http_links -eq 0 ]; then
        print_status "SUCCESS" "All links use HTTPS or are localhost"
    fi
}

# Function to generate security report
generate_report() {
    local report_file="security-scan-report-$(date +%Y%m%d-%H%M%S).md"
    
    cat > "$report_file" << REPORT_EOF
# Security Scan Report

**Date:** $(date)
**Scanner:** Comprehensive Security Scanner
**Repository:** $(basename "$(pwd)")

## Scan Summary

| Severity | Count |
|----------|-------|
| Critical | $CRITICAL_ISSUES |
| High     | $HIGH_ISSUES |
| Medium   | $MEDIUM_ISSUES |
| Low      | $LOW_ISSUES |
| **Total** | **$TOTAL_ISSUES** |

## Scanned Resources

- ✅ Website files (HTML, CSS, JavaScript)
- ✅ Admin site files
- ✅ Terraform infrastructure files
- ✅ Lambda function code
- ✅ Shell and PowerShell scripts
- ✅ Configuration files (JSON)
- ✅ Client templates
- ✅ Security headers
- ✅ HTTP/HTTPS links

## Recommendations

REPORT_EOF

    if [ $CRITICAL_ISSUES -gt 0 ]; then
        echo "- 🚨 **CRITICAL**: Fix $CRITICAL_ISSUES critical security issues immediately" >> "$report_file"
    fi
    
    if [ $HIGH_ISSUES -gt 0 ]; then
        echo "- ⚠️ **HIGH**: Address $HIGH_ISSUES high-severity security issues" >> "$report_file"
    fi
    
    if [ $MEDIUM_ISSUES -gt 0 ]; then
        echo "- 📋 **MEDIUM**: Review $MEDIUM_ISSUES medium-severity issues" >> "$report_file"
    fi
    
    if [ $LOW_ISSUES -gt 0 ]; then
        echo "- ℹ️ **LOW**: Consider addressing $LOW_ISSUES low-severity issues" >> "$report_file"
    fi
    
    if [ $TOTAL_ISSUES -eq 0 ]; then
        echo "- ✅ **EXCELLENT**: No security issues found!" >> "$report_file"
    fi
    
    echo "" >> "$report_file"
    echo "## Next Steps" >> "$report_file"
    echo "1. Review all identified issues" >> "$report_file"
    echo "2. Fix critical and high-severity issues immediately" >> "$report_file"
    echo "3. Implement security best practices" >> "$report_file"
    echo "4. Run regular security scans" >> "$report_file"
    
    print_status "INFO" "Security report generated: $report_file"
}

# Main execution
main() {
    echo "🔒 Starting Comprehensive Security Scan"
    echo "======================================"
    echo ""
    
    # Check if we're in the right directory
    if [ ! -d "website" ] && [ ! -d "terraform" ] && [ ! -d "lambda" ]; then
        print_status "ERROR" "Please run this script from the repository root directory"
        exit 1
    fi
    
    # Run all security scans
    scan_secrets "website" "*.js" "HIGH"
    scan_secrets "website" "*.html" "HIGH"
    scan_secrets "admin" "*.js" "HIGH"
    scan_secrets "admin" "*.html" "HIGH"
    scan_secrets "client-template" "*.js" "MEDIUM"
    scan_secrets "client-content-template" "*.js" "MEDIUM"
    scan_secrets "skeleton-client" "*.js" "MEDIUM"
    
    scan_terraform
    scan_lambda
    scan_scripts
    scan_configs
    scan_security_headers
    scan_http_links
    
    echo ""
    echo "🔒 Security Scan Complete"
    echo "========================"
    echo ""
    
    # Print summary
    print_status "INFO" "Scan Summary:"
    echo "  Critical Issues: $CRITICAL_ISSUES"
    echo "  High Issues: $HIGH_ISSUES"
    echo "  Medium Issues: $MEDIUM_ISSUES"
    echo "  Low Issues: $LOW_ISSUES"
    echo "  Total Issues: $TOTAL_ISSUES"
    echo ""
    
    # Generate report
    generate_report
    
    # Exit with appropriate code
    if [ $CRITICAL_ISSUES -gt 0 ]; then
        print_status "ERROR" "Critical security issues found! Please fix immediately."
        exit 1
    elif [ $HIGH_ISSUES -gt 5 ]; then
        print_status "ERROR" "Too many high-severity issues found! Please review and fix."
        exit 1
    elif [ $TOTAL_ISSUES -eq 0 ]; then
        print_status "SUCCESS" "No security issues found! Repository is secure."
        exit 0
    else
        print_status "WARNING" "Security issues found. Please review the report."
        exit 0
    fi
}

# Run main function
main "$@"
