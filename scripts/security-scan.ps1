# Comprehensive Security Scanning Script (PowerShell)
# For private repositories that need external security scanning

param(
    [switch]$SkipCritical,
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Counters
$script:TotalIssues = 0
$script:CriticalIssues = 0
$script:HighIssues = 0
$script:MediumIssues = 0
$script:LowIssues = 0

# Function to print colored output
function Write-Status {
    param(
        [string]$Status,
        [string]$Message
    )
    
    switch ($Status) {
        "SUCCESS" { Write-Host "✅ $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "❌ $Message" -ForegroundColor Red }
        "INFO" { Write-Host "ℹ️  $Message" -ForegroundColor Blue }
    }
}

# Function to increment counters
function Add-Issue {
    param([string]$Severity)
    
    $script:TotalIssues++
    switch ($Severity) {
        "CRITICAL" { $script:CriticalIssues++ }
        "HIGH" { $script:HighIssues++ }
        "MEDIUM" { $script:MediumIssues++ }
        "LOW" { $script:LowIssues++ }
    }
}

# Function to scan for secrets
function Scan-Secrets {
    param(
        [string]$Directory,
        [string]$FilePattern,
        [string]$Severity = "HIGH"
    )
    
    Write-Status "INFO" "Scanning $Directory for secrets in $FilePattern files..."
    
    $secretsFound = 0
    
    # Check for hardcoded passwords
    $passwordFiles = Get-ChildItem -Path $Directory -Filter $FilePattern -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'password\s*=\s*["\'][^"\']{4,}["\']' | 
        Where-Object { $_.Line -notmatch "placeholder|example|test" }
    
    if ($passwordFiles) {
        Write-Status "ERROR" "Hardcoded passwords found in $Directory"
        Add-Issue $Severity
        $secretsFound++
    }
    
    # Check for API keys
    $apiKeyFiles = Get-ChildItem -Path $Directory -Filter $FilePattern -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'api.*key\s*=\s*["\'][^"\']{8,}["\']'
    
    if ($apiKeyFiles) {
        Write-Status "ERROR" "Hardcoded API keys found in $Directory"
        Add-Issue $Severity
        $secretsFound++
    }
    
    # Check for tokens
    $tokenFiles = Get-ChildItem -Path $Directory -Filter $FilePattern -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'token\s*=\s*["\'][^"\']{8,}["\']' | 
        Where-Object { $_.Line -notmatch "placeholder|example|test" }
    
    if ($tokenFiles) {
        Write-Status "ERROR" "Hardcoded tokens found in $Directory"
        Add-Issue $Severity
        $secretsFound++
    }
    
    # Check for AWS credentials
    $awsFiles = Get-ChildItem -Path $Directory -Filter $FilePattern -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern '(aws_access_key|aws_secret_key)\s*=\s*["\'][^"\']{8,}["\']'
    
    if ($awsFiles) {
        Write-Status "ERROR" "Hardcoded AWS credentials found in $Directory"
        Add-Issue $Severity
        $secretsFound++
    }
    
    if ($secretsFound -eq 0) {
        Write-Status "SUCCESS" "No secrets found in $Directory"
    }
}

# Function to scan Terraform files
function Scan-Terraform {
    Write-Status "INFO" "Scanning Terraform files for security issues..."
    
    $terraformIssues = 0
    
    # Check for hardcoded AWS access keys
    $accessKeyFiles = Get-ChildItem -Path "terraform" -Filter "*.tf" -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'aws_access_key\s*=\s*["\'][^"\']{8,}["\']'
    
    if ($accessKeyFiles) {
        Write-Status "ERROR" "Hardcoded AWS access keys in Terraform files"
        Add-Issue "CRITICAL"
        $terraformIssues++
    }
    
    # Check for hardcoded AWS secret keys
    $secretKeyFiles = Get-ChildItem -Path "terraform" -Filter "*.tf" -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'aws_secret_key\s*=\s*["\'][^"\']{8,}["\']'
    
    if ($secretKeyFiles) {
        Write-Status "ERROR" "Hardcoded AWS secret keys in Terraform files"
        Add-Issue "CRITICAL"
        $terraformIssues++
    }
    
    # Check for sensitive data marked as non-sensitive
    $sensitiveFiles = Get-ChildItem -Path "terraform" -Filter "*.tf" -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'sensitive\s*=\s*false'
    
    if ($sensitiveFiles) {
        Write-Status "WARNING" "Sensitive variables marked as non-sensitive in Terraform"
        Add-Issue "MEDIUM"
        $terraformIssues++
    }
    
    # Check for hardcoded passwords
    $passwordFiles = Get-ChildItem -Path "terraform" -Filter "*.tf" -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'password\s*=\s*["\'][^"\']{4,}["\']' | 
        Where-Object { $_.Line -notmatch "default.*=.*\"" }
    
    if ($passwordFiles) {
        Write-Status "ERROR" "Hardcoded passwords in Terraform files"
        Add-Issue "HIGH"
        $terraformIssues++
    }
    
    if ($terraformIssues -eq 0) {
        Write-Status "SUCCESS" "No security issues found in Terraform files"
    }
}

# Function to scan Lambda functions
function Scan-Lambda {
    Write-Status "INFO" "Scanning Lambda functions for security issues..."
    
    $lambdaIssues = 0
    
    # Check for hardcoded credentials
    $credentialFiles = Get-ChildItem -Path "lambda" -Include "*.js", "*.py", "*.ts" -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern '(aws_access_key|aws_secret_key|password|token)\s*=\s*["\'][^"\']{8,}["\']'
    
    if ($credentialFiles) {
        Write-Status "ERROR" "Hardcoded credentials in Lambda functions"
        Add-Issue "HIGH"
        $lambdaIssues++
    }
    
    # Check for sensitive data logging
    $loggingFiles = Get-ChildItem -Path "lambda" -Filter "*.js" -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'console\.log.*password|console\.log.*token|console\.log.*key'
    
    if ($loggingFiles) {
        Write-Status "WARNING" "Potential sensitive data logging in Lambda functions"
        Add-Issue "MEDIUM"
        $lambdaIssues++
    }
    
    if ($lambdaIssues -eq 0) {
        Write-Status "SUCCESS" "No security issues found in Lambda functions"
    }
}

# Function to scan shell scripts
function Scan-Scripts {
    Write-Status "INFO" "Scanning shell scripts for security issues..."
    
    $scriptIssues = 0
    
    # Check for hardcoded passwords
    $passwordFiles = Get-ChildItem -Path "scripts" -Include "*.sh", "*.ps1" -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'password\s*=\s*["\'][^"\']{4,}["\']' | 
        Where-Object { $_.Line -notmatch "echo.*password" }
    
    if ($passwordFiles) {
        Write-Status "ERROR" "Hardcoded passwords in scripts"
        Add-Issue "HIGH"
        $scriptIssues++
    }
    
    # Check for hardcoded API keys
    $apiKeyFiles = Get-ChildItem -Path "scripts" -Include "*.sh", "*.ps1" -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'api.*key\s*=\s*["\'][^"\']{8,}["\']'
    
    if ($apiKeyFiles) {
        Write-Status "ERROR" "Hardcoded API keys in scripts"
        Add-Issue "HIGH"
        $scriptIssues++
    }
    
    # Check for dangerous commands
    $dangerousFiles = Get-ChildItem -Path "scripts" -Filter "*.sh" -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'rm\s+-rf\s+/|chmod\s+777|chown\s+-R\s+root'
    
    if ($dangerousFiles) {
        Write-Status "WARNING" "Potentially dangerous commands found in scripts"
        Add-Issue "MEDIUM"
        $scriptIssues++
    }
    
    if ($scriptIssues -eq 0) {
        Write-Status "SUCCESS" "No security issues found in scripts"
    }
}

# Function to scan configuration files
function Scan-Configs {
    Write-Status "INFO" "Scanning configuration files for security issues..."
    
    $configIssues = 0
    
    # Check for hardcoded credentials in JSON files
    $credentialFiles = Get-ChildItem -Path "." -Filter "*.json" -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { $_.FullName -notmatch "node_modules|\.git" } | 
        Select-String -Pattern '(password|token|key|secret)\s*:\s*["\'][^"\']{4,}["\']' | 
        Where-Object { $_.Line -notmatch "placeholder|example|test" }
    
    if ($credentialFiles) {
        Write-Status "ERROR" "Hardcoded credentials in configuration files"
        Add-Issue "HIGH"
        $configIssues++
    }
    
    # Check for AWS account IDs
    $accountIdFiles = Get-ChildItem -Path "." -Filter "*.json" -Recurse -ErrorAction SilentlyContinue | 
        Where-Object { $_.FullName -notmatch "node_modules|\.git" } | 
        Select-String -Pattern 'account.*id\s*:\s*["\'][0-9]{12}["\']'
    
    if ($accountIdFiles) {
        Write-Status "WARNING" "Hardcoded AWS account IDs in configuration files"
        Add-Issue "LOW"
        $configIssues++
    }
    
    if ($configIssues -eq 0) {
        Write-Status "SUCCESS" "No security issues found in configuration files"
    }
}

# Function to scan for security headers
function Scan-SecurityHeaders {
    Write-Status "INFO" "Scanning for security headers in HTML files..."
    
    $headerIssues = 0
    
    # Check for missing CSP headers
    $htmlFiles = Get-ChildItem -Path "." -Filter "*.html" -Recurse -ErrorAction SilentlyContinue
    $missingCspFiles = $htmlFiles | Where-Object { 
        (Get-Content $_.FullName -Raw) -notmatch "Content-Security-Policy" 
    }
    
    if ($missingCspFiles) {
        Write-Status "WARNING" "Missing Content-Security-Policy headers in HTML files"
        Add-Issue "MEDIUM"
        $headerIssues++
    }
    
    if ($headerIssues -eq 0) {
        Write-Status "SUCCESS" "Security headers present in HTML files"
    }
}

# Function to scan for HTTP links
function Scan-HttpLinks {
    Write-Status "INFO" "Scanning for HTTP links (should use HTTPS)..."
    
    $httpLinks = 0
    
    # Check for HTTP links in HTML and JS files
    $httpFiles = Get-ChildItem -Path "." -Include "*.html", "*.js" -Recurse -ErrorAction SilentlyContinue | 
        Select-String -Pattern 'http://' | 
        Where-Object { $_.Line -notmatch "localhost|127\.0\.0\.1" }
    
    if ($httpFiles) {
        Write-Status "WARNING" "HTTP links found (should use HTTPS)"
        Add-Issue "LOW"
        $httpLinks++
    }
    
    if ($httpLinks -eq 0) {
        Write-Status "SUCCESS" "All links use HTTPS or are localhost"
    }
}

# Function to generate security report
function Generate-Report {
    $reportFile = "security-scan-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
    
    $reportContent = @"
# Security Scan Report

**Date:** $(Get-Date)
**Scanner:** Comprehensive Security Scanner (PowerShell)
**Repository:** $(Split-Path -Leaf (Get-Location))

## Scan Summary

| Severity | Count |
|----------|-------|
| Critical | $script:CriticalIssues |
| High     | $script:HighIssues |
| Medium   | $script:MediumIssues |
| Low      | $script:LowIssues |
| **Total** | **$script:TotalIssues** |

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

"@

    if ($script:CriticalIssues -gt 0) {
        $reportContent += "`n- 🚨 **CRITICAL**: Fix $($script:CriticalIssues) critical security issues immediately"
    }
    
    if ($script:HighIssues -gt 0) {
        $reportContent += "`n- ⚠️ **HIGH**: Address $($script:HighIssues) high-severity security issues"
    }
    
    if ($script:MediumIssues -gt 0) {
        $reportContent += "`n- 📋 **MEDIUM**: Review $($script:MediumIssues) medium-severity issues"
    }
    
    if ($script:LowIssues -gt 0) {
        $reportContent += "`n- ℹ️ **LOW**: Consider addressing $($script:LowIssues) low-severity issues"
    }
    
    if ($script:TotalIssues -eq 0) {
        $reportContent += "`n- ✅ **EXCELLENT**: No security issues found!"
    }
    
    $reportContent += @"

## Next Steps
1. Review all identified issues
2. Fix critical and high-severity issues immediately
3. Implement security best practices
4. Run regular security scans
"@

    $reportContent | Out-File -FilePath $reportFile -Encoding UTF8
    Write-Status "INFO" "Security report generated: $reportFile"
}

# Main execution
function Main {
    Write-Host "🔒 Starting Comprehensive Security Scan" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if we're in the right directory
    if (-not (Test-Path "website") -and -not (Test-Path "terraform") -and -not (Test-Path "lambda")) {
        Write-Status "ERROR" "Please run this script from the repository root directory"
        exit 1
    }
    
    # Run all security scans
    Scan-Secrets "website" "*.js" "HIGH"
    Scan-Secrets "website" "*.html" "HIGH"
    Scan-Secrets "admin" "*.js" "HIGH"
    Scan-Secrets "admin" "*.html" "HIGH"
    Scan-Secrets "client-template" "*.js" "MEDIUM"
    Scan-Secrets "client-content-template" "*.js" "MEDIUM"
    Scan-Secrets "skeleton-client" "*.js" "MEDIUM"
    
    Scan-Terraform
    Scan-Lambda
    Scan-Scripts
    Scan-Configs
    Scan-SecurityHeaders
    Scan-HttpLinks
    
    Write-Host ""
    Write-Host "🔒 Security Scan Complete" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    
    # Print summary
    Write-Status "INFO" "Scan Summary:"
    Write-Host "  Critical Issues: $script:CriticalIssues"
    Write-Host "  High Issues: $script:HighIssues"
    Write-Host "  Medium Issues: $script:MediumIssues"
    Write-Host "  Low Issues: $script:LowIssues"
    Write-Host "  Total Issues: $script:TotalIssues"
    Write-Host ""
    
    # Generate report
    Generate-Report
    
    # Exit with appropriate code
    if ($script:CriticalIssues -gt 0) {
        Write-Status "ERROR" "Critical security issues found! Please fix immediately."
        exit 1
    } elseif ($script:HighIssues -gt 5) {
        Write-Status "ERROR" "Too many high-severity issues found! Please review and fix."
        exit 1
    } elseif ($script:TotalIssues -eq 0) {
        Write-Status "SUCCESS" "No security issues found! Repository is secure."
        exit 0
    } else {
        Write-Status "WARNING" "Security issues found. Please review the report."
        exit 0
    }
}

# Run main function
Main
