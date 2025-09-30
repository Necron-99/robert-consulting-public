# Domain Setup Guide for robert-consulting.net

This guide explains how to set up your custom domain with SSL certificate for robert-consulting.net.

## Prerequisites

1. **Domain Ownership**: You must own the domain robert-consulting.net
2. **AWS Access**: Ensure you have the necessary AWS permissions
3. **Terraform**: Version >= 1.0 installed

## Step 1: Update DNS at Your Domain Registrar

Before running Terraform, you need to update your domain's nameservers at your domain registrar.

### After Terraform Creates the Hosted Zone:

1. **Get the Name Servers**:
   ```bash
   cd terraform
   terraform apply
   terraform output name_servers
   ```

2. **Update at Your Domain Registrar**:
   - Log into your domain registrar (GoDaddy, Namecheap, etc.)
   - Find the DNS/Nameserver settings for robert-consulting.net
   - Replace the existing nameservers with the 4 nameservers from Terraform output
   - Save the changes

## Step 2: Deploy the Infrastructure

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform (if not already done)
terraform init

# Review the plan
terraform plan

# Apply the infrastructure
terraform apply
```

## Step 3: Verify SSL Certificate

The SSL certificate will be automatically validated via DNS records. This process typically takes 5-10 minutes.

### Check Certificate Status:
```bash
terraform output certificate_status
```

## Step 4: Test Your Domain

Once the certificate is validated:

1. **Primary Domain**: https://robert-consulting.net
2. **WWW Subdomain**: https://www.robert-consulting.net

## What This Setup Provides

### SSL Certificate
- **Wildcard Certificate**: Covers *.robert-consulting.net
- **Automatic Renewal**: AWS handles certificate renewal
- **Strong Security**: TLS 1.2+ with modern cipher suites

### DNS Configuration
- **Route 53 Hosted Zone**: Manages your domain DNS
- **A Records**: Directs traffic to CloudFront
- **CNAME**: www.robert-consulting.net redirects to main domain
- **IPv6 Support**: AAAA records for modern connectivity

### CloudFront Integration
- **Custom SSL**: Uses your wildcard certificate
- **HTTPS Redirect**: All HTTP traffic redirects to HTTPS
- **Global CDN**: Fast content delivery worldwide

## Troubleshooting

### Certificate Not Validating
1. Check that nameservers are updated at your registrar
2. Wait 5-10 minutes for DNS propagation
3. Verify DNS records: `terraform output name_servers`

### Domain Not Resolving
1. Ensure nameservers are correctly set at registrar
2. Wait for DNS propagation (up to 48 hours)
3. Check Route 53 hosted zone: `terraform output hosted_zone_id`

### SSL Certificate Issues
1. Verify certificate is in us-east-1 region
2. Check certificate status: `terraform output certificate_status`
3. Ensure CloudFront distribution is using the certificate

## Cost Considerations

### Route 53 Costs
- **Hosted Zone**: $0.50/month
- **DNS Queries**: $0.40 per million queries
- **Health Checks**: $0.50/month per health check

### ACM Certificate
- **Free**: SSL certificates are free in AWS
- **No Renewal Costs**: Automatic renewal at no charge

### CloudFront
- **No Additional Cost**: Using existing CloudFront distribution
- **HTTPS Requests**: Same pricing as HTTP requests

## Security Features

1. **TLS 1.2+**: Modern encryption protocols
2. **HSTS Headers**: HTTP Strict Transport Security
3. **Perfect Forward Secrecy**: Enhanced security
4. **Certificate Transparency**: Public certificate logs

## Next Steps

After successful setup:

1. **Test HTTPS**: Verify SSL certificate is working
2. **Monitor Costs**: Set up billing alerts
3. **Performance**: Monitor CloudFront metrics
4. **Security**: Review security headers and SSL configuration

## Support

If you encounter issues:

1. Check Terraform outputs for configuration details
2. Verify AWS Console for resource status
3. Review CloudWatch logs for any errors
4. Ensure all DNS changes have propagated

## Important Notes

- **DNS Propagation**: Can take up to 48 hours globally
- **Certificate Validation**: Usually completes within 10 minutes
- **CloudFront Deployment**: May take 15-20 minutes
- **Backup**: Your existing CloudFront distribution remains functional during setup

