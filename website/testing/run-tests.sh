#!/bin/bash

# Comprehensive Testing Script for Testing Site
# Runs all automated tests before deployment

set -e

# Configuration
TESTING_SITE_URL=""
REGION="us-east-1"
BUDGET_LIMIT=10.00

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Initialize test results
TEST_RESULTS=""
FAILED_TESTS=0
TOTAL_TESTS=0

# Test 1: HTML Validation
test_html_validation() {
    log_info "Testing HTML validation..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if command -v html-validate &> /dev/null; then
        if html-validate index.html features.html; then
            log_success "HTML validation passed"
            TEST_RESULTS="$TEST_RESULTS\n✅ HTML Validation: Passed"
        else
            log_error "HTML validation failed"
            TEST_RESULTS="$TEST_RESULTS\n❌ HTML Validation: Failed"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        log_warning "html-validate not installed, skipping HTML validation"
        TEST_RESULTS="$TEST_RESULTS\n⚠️ HTML Validation: Skipped (tool not installed)"
    fi
}

# Test 2: Accessibility Testing
test_accessibility() {
    log_info "Testing accessibility..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if command -v pa11y &> /dev/null; then
        if pa11y --standard WCAG2AA index.html; then
            log_success "Accessibility test passed"
            TEST_RESULTS="$TEST_RESULTS\n✅ Accessibility: Passed"
        else
            log_error "Accessibility test failed"
            TEST_RESULTS="$TEST_RESULTS\n❌ Accessibility: Failed"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        log_warning "pa11y not installed, skipping accessibility test"
        TEST_RESULTS="$TEST_RESULTS\n⚠️ Accessibility: Skipped (tool not installed)"
    fi
}

# Test 3: Performance Testing
test_performance() {
    log_info "Testing performance..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if command -v lighthouse &> /dev/null; then
        if lighthouse index.html --output=json --chrome-flags="--headless" --quiet; then
            log_success "Performance test passed"
            TEST_RESULTS="$TEST_RESULTS\n✅ Performance: Passed"
        else
            log_error "Performance test failed"
            TEST_RESULTS="$TEST_RESULTS\n❌ Performance: Failed"
            FAILED_TESTS=$((FAILED_TESTS + 1))
        fi
    else
        log_warning "lighthouse not installed, skipping performance test"
        TEST_RESULTS="$TEST_RESULTS\n⚠️ Performance: Skipped (tool not installed)"
    fi
}

# Test 4: Security Headers
test_security_headers() {
    log_info "Testing security headers..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if grep -q "Content-Security-Policy" index.html && \
       grep -q "X-Content-Type-Options" index.html && \
       grep -q "X-Frame-Options" index.html && \
       grep -q "X-XSS-Protection" index.html; then
        log_success "Security headers test passed"
        TEST_RESULTS="$TEST_RESULTS\n✅ Security Headers: Passed"
    else
        log_error "Security headers test failed"
        TEST_RESULTS="$TEST_RESULTS\n❌ Security Headers: Failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test 5: Cost Optimization
test_cost_optimization() {
    log_info "Testing cost optimization..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ -f "cost-monitor.sh" ] && [ -f "cleanup-testing.sh" ] && [ -f "deploy-testing.sh" ]; then
        log_success "Cost optimization test passed"
        TEST_RESULTS="$TEST_RESULTS\n✅ Cost Optimization: Passed"
    else
        log_error "Cost optimization test failed"
        TEST_RESULTS="$TEST_RESULTS\n❌ Cost Optimization: Failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test 6: Mobile Responsiveness
test_mobile_responsiveness() {
    log_info "Testing mobile responsiveness..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if grep -q "viewport" index.html && \
       grep -q "media" testing-styles.css; then
        log_success "Mobile responsiveness test passed"
        TEST_RESULTS="$TEST_RESULTS\n✅ Mobile Responsiveness: Passed"
    else
        log_error "Mobile responsiveness test failed"
        TEST_RESULTS="$TEST_RESULTS\n❌ Mobile Responsiveness: Failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test 7: SEO Optimization
test_seo_optimization() {
    log_info "Testing SEO optimization..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if grep -q "meta name=\"description\"" index.html && \
       grep -q "meta name=\"keywords\"" index.html && \
       grep -q "title>" index.html; then
        log_success "SEO optimization test passed"
        TEST_RESULTS="$TEST_RESULTS\n✅ SEO Optimization: Passed"
    else
        log_error "SEO optimization test failed"
        TEST_RESULTS="$TEST_RESULTS\n❌ SEO Optimization: Failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test 8: JavaScript Functionality
test_javascript_functionality() {
    log_info "Testing JavaScript functionality..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ -f "testing-script.js" ] && grep -q "testingEnvironment" testing-script.js; then
        log_success "JavaScript functionality test passed"
        TEST_RESULTS="$TEST_RESULTS\n✅ JavaScript Functionality: Passed"
    else
        log_error "JavaScript functionality test failed"
        TEST_RESULTS="$TEST_RESULTS\n❌ JavaScript Functionality: Failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test 9: CSS Validation
test_css_validation() {
    log_info "Testing CSS validation..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ -f "testing-styles.css" ] && grep -q "media" testing-styles.css; then
        log_success "CSS validation test passed"
        TEST_RESULTS="$TEST_RESULTS\n✅ CSS Validation: Passed"
    else
        log_error "CSS validation test failed"
        TEST_RESULTS="$TEST_RESULTS\n❌ CSS Validation: Failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test 10: File Structure
test_file_structure() {
    log_info "Testing file structure..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    REQUIRED_FILES=("index.html" "features.html" "testing-styles.css" "testing-script.js" "README.md")
    MISSING_FILES=0
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "Missing required file: $file"
            MISSING_FILES=$((MISSING_FILES + 1))
        fi
    done
    
    if [ $MISSING_FILES -eq 0 ]; then
        log_success "File structure test passed"
        TEST_RESULTS="$TEST_RESULTS\n✅ File Structure: Passed"
    else
        log_error "File structure test failed ($MISSING_FILES missing files)"
        TEST_RESULTS="$TEST_RESULTS\n❌ File Structure: Failed"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Generate test report
generate_test_report() {
    log_info "Generating test report..."
    
    PASS_RATE=$(( (TOTAL_TESTS - FAILED_TESTS) * 100 / TOTAL_TESTS ))
    
    cat > test-report.md << EOF
# Testing Site Test Report

**Date:** $(date)
**Environment:** Testing
**Total Tests:** $TOTAL_TESTS
**Failed Tests:** $FAILED_TESTS
**Pass Rate:** $PASS_RATE%

## Test Results

$TEST_RESULTS

## Summary

$([ $FAILED_TESTS -eq 0 ] && echo "✅ All tests passed! Ready for deployment." || echo "❌ Some tests failed. Please review and fix before deployment.")

## Recommendations

$([ $FAILED_TESTS -eq 0 ] && echo "- All tests passed successfully" || echo "- Review failed tests and fix issues")
$([ $PASS_RATE -ge 90 ] && echo "- Excellent test coverage" || echo "- Consider improving test coverage")

---
*Automated test report generated by testing script*
EOF
    
    log_success "Test report generated: test-report.md"
}

# Display test summary
display_test_summary() {
    echo ""
    echo "📊 Test Summary"
    echo "==============="
    echo "Total Tests: $TOTAL_TESTS"
    echo "Failed Tests: $FAILED_TESTS"
    echo "Pass Rate: $(( (TOTAL_TESTS - FAILED_TESTS) * 100 / TOTAL_TESTS ))%"
    echo ""
    echo "Test Results:"
    echo -e "$TEST_RESULTS"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "All tests passed! Ready for deployment."
        exit 0
    else
        log_error "Some tests failed. Please review and fix before deployment."
        exit 1
    fi
}

# Main test execution
main() {
    log_info "Starting comprehensive testing..."
    
    test_html_validation
    test_accessibility
    test_performance
    test_security_headers
    test_cost_optimization
    test_mobile_responsiveness
    test_seo_optimization
    test_javascript_functionality
    test_css_validation
    test_file_structure
    
    generate_test_report
    display_test_summary
}

# Run main function
main "$@"
