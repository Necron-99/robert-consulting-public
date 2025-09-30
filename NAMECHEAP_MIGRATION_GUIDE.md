# Namecheap to AWS Migration Guide

## Current Setup Analysis

### Your Current Configuration:
- **Domain**: robert-consulting.net (hosted at Namecheap)
- **WWW CNAME**: www.robert-consulting.net → dpm4biqgmoi9l.cloudfront.net
- **CloudFront ID**: E36DBYPHUUKB3V (from your Terraform)
- **Status**: Domain transfer to AWS in progress

## Migration Strategy

### Phase 1: Optimize Current Setup (Immediate)
Since you already have a working CNAME setup, let's optimize it first:

1. **Add SSL Certificate to Current CloudFront**
2. **Update CloudFront with custom domain**
3. **Prepare for seamless migration**

### Phase 2: Gradual Migration (During Transfer)
1. **Set up Route 53 hosted zone**
2. **Create SSL certificate**
3. **Test with subdomain first**
4. **Switch DNS gradually**

### Phase 3: Complete Migration (After Transfer)
1. **Update all DNS records**
2. **Remove Namecheap dependencies**
3. **Optimize for AWS-native features**

## Immediate Actions

### 1. Add SSL Certificate to Current CloudFront

Since your domain is still at Namecheap, we can:
- Create the SSL certificate now
- Add it to your existing CloudFront distribution
- Update the CNAME to use HTTPS

### 2. Update Namecheap DNS Records

**Current**: `www.robert-consulting.net` → `dpm4biqgmoi9l.cloudfront.net`

**Recommended**: 
- Keep the CNAME for now
- Add A record for root domain: `robert-consulting.net` → CloudFront IP
- This will work with SSL certificate

## Step-by-Step Implementation

### Option 1: Automated Script (Recommended)
Choose the script for your platform:

**Windows PowerShell:**
```powershell
cd terraform
.\update-current-cloudfront.ps1
```

**Windows Command Prompt:**
```cmd
cd terraform
update-current-cloudfront.bat
```

**Linux/macOS:**
```bash
cd terraform
chmod +x update-current-cloudfront.sh
./update-current-cloudfront.sh
```

### Option 2: Manual Terraform Commands
```bash
cd terraform
terraform apply -target=aws_acm_certificate.wildcard
terraform apply -target=aws_route53_zone.main
terraform apply -target=aws_route53_record.cert_validation
terraform apply -target=aws_acm_certificate_validation.wildcard
terraform apply -target=aws_cloudfront_distribution.website
```

### Step 3: Update Namecheap DNS
**Add these records at Namecheap:**

1. **A Record**: `robert-consulting.net` → CloudFront IP
2. **CNAME**: `www.robert-consulting.net` → `dpm4biqgmoi9l.cloudfront.net` (keep existing)
3. **CNAME**: `api.robert-consulting.net` → `dpm4biqgmoi9l.cloudfront.net` (optional)

### Step 4: Test HTTPS
- https://robert-consulting.net
- https://www.robert-consulting.net

## Benefits of This Approach

### Immediate Benefits:
- ✅ **SSL Certificate**: Secure HTTPS immediately
- ✅ **No Downtime**: Current setup continues working
- ✅ **Wildcard Support**: Covers all subdomains
- ✅ **Cost Effective**: No additional costs

### Migration Benefits:
- ✅ **Gradual Transition**: No service interruption
- ✅ **Testing Phase**: Verify everything works
- ✅ **Rollback Option**: Can revert if needed
- ✅ **AWS Native**: Full AWS features when ready

## Cost Analysis

### Current Costs (Namecheap):
- **Domain Registration**: Your existing cost
- **DNS Management**: Usually free
- **SSL Certificate**: Free (AWS ACM)

### Future Costs (AWS Route 53):
- **Hosted Zone**: $0.50/month
- **DNS Queries**: $0.40 per million
- **Total**: ~$0.50/month + query costs

## Timeline

### Immediate (Today):
- [ ] Create SSL certificate
- [ ] Update CloudFront distribution
- [ ] Test HTTPS functionality

### Short-term (1-2 weeks):
- [ ] Monitor SSL certificate status
- [ ] Test all subdomains
- [ ] Optimize CloudFront settings

### Long-term (After domain transfer):
- [ ] Migrate to Route 53
- [ ] Remove Namecheap dependencies
- [ ] Full AWS-native setup

## Troubleshooting

### SSL Certificate Issues:
```bash
# Check certificate status
terraform output certificate_status

# Verify DNS validation
nslookup _acme-challenge.robert-consulting.net
```

### CloudFront Issues:
```bash
# Check distribution status
aws cloudfront get-distribution --id E36DBYPHUUKB3V

# Invalidate cache if needed
aws cloudfront create-invalidation --distribution-id E36DBYPHUUKB3V --paths "/*"
```

### DNS Issues:
```bash
# Test DNS resolution
nslookup robert-consulting.net
nslookup www.robert-consulting.net
```

## Next Steps

1. **Run the SSL certificate creation**
2. **Update your CloudFront distribution**
3. **Test HTTPS functionality**
4. **Monitor the domain transfer progress**
5. **Plan the Route 53 migration**

This approach gives you immediate SSL benefits while preparing for a smooth AWS migration!
