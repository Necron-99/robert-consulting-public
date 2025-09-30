@echo off
REM Update Current CloudFront Distribution with SSL Certificate
REM This script updates your existing CloudFront distribution (E36DBYPHUUKB3V) with SSL certificate

echo 🔒 Updating CloudFront Distribution with SSL Certificate
echo =======================================================

REM Check if we're in the terraform directory
if not exist "domain-namecheap.tf" (
    echo ❌ Error: Please run this script from the terraform directory
    echo Expected files: domain-namecheap.tf, infrastructure.tf
    exit /b 1
)

REM Check if AWS CLI is configured
echo 🔍 Checking AWS configuration...
aws sts get-caller-identity >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error: AWS CLI not configured or no valid credentials
    echo Please run: aws configure
    exit /b 1
)

echo ✅ AWS credentials verified

REM Initialize Terraform if needed
echo 🔧 Initializing Terraform...
terraform init

REM Step 1: Create SSL Certificate
echo 📜 Step 1: Creating SSL Certificate...
echo Creating wildcard certificate for *.robertconsulting.net

terraform apply -target=aws_acm_certificate.wildcard -auto-approve
if %errorlevel% neq 0 (
    echo ❌ Error creating SSL certificate
    exit /b 1
)

echo ✅ SSL Certificate created successfully

REM Step 2: Create DNS validation records
echo 📜 Step 2: Creating DNS validation records...
echo This will create Route 53 records for certificate validation

terraform apply -target=aws_route53_zone.main -auto-approve
terraform apply -target=aws_route53_record.cert_validation -auto-approve
if %errorlevel% neq 0 (
    echo ❌ Error creating DNS validation records
    exit /b 1
)

echo ✅ DNS validation records created

REM Step 3: Validate certificate
echo 📜 Step 3: Validating SSL Certificate...
echo This may take 5-10 minutes...

terraform apply -target=aws_acm_certificate_validation.wildcard -auto-approve
if %errorlevel% neq 0 (
    echo ❌ Error validating SSL certificate
    exit /b 1
)

echo ✅ SSL Certificate validated successfully

REM Step 4: Update CloudFront Distribution
echo 📜 Step 4: Updating CloudFront Distribution...
echo Updating distribution E36DBYPHUUKB3V with SSL certificate

terraform apply -target=aws_cloudfront_distribution.website -auto-approve
if %errorlevel% neq 0 (
    echo ❌ Error updating CloudFront distribution
    exit /b 1
)

echo ✅ CloudFront distribution updated successfully

REM Get the outputs
echo.
echo 📊 SSL Certificate Setup Completed!
echo ====================================

echo 🔒 SSL Certificate Details:
for /f "tokens=*" %%i in ('terraform output -raw certificate_status') do echo    Status: %%i

echo.
echo 🌐 DNS Configuration for Namecheap:
echo You need to add these records at Namecheap:
echo.
echo 1. A Record:
echo    Name: @ (or robertconsulting.net)
echo    Value: [CloudFront IP - get from AWS Console]
echo.
echo 2. CNAME Record (keep existing):
echo    Name: www
echo    Value: dpm4biqgmoi9l.cloudfront.net
echo.
echo 3. CNAME Record (optional for subdomains):
echo    Name: api (or any subdomain)
echo    Value: dpm4biqgmoi9l.cloudfront.net

echo.
echo 📋 Next Steps:
echo 1. Add the DNS records above at Namecheap
echo 2. Wait 5-10 minutes for DNS propagation
echo 3. Test HTTPS: https://robertconsulting.net
echo 4. Test WWW: https://www.robertconsulting.net

echo.
echo 🔍 To monitor certificate status:
echo    terraform output certificate_status

echo.
echo ⚠️  Important Notes:
echo - Your current CNAME setup will continue working
echo - SSL certificate covers *.robertconsulting.net
echo - No downtime during this process
echo - You can test HTTPS immediately after DNS updates

echo.
echo ✅ CloudFront SSL update completed!

