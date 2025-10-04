# Quick Terraform State Fix

## 🚨 **Immediate Fix Commands**

Run these commands in order to fix your Terraform state:

### **Step 1: Destroy the problematic certificate validation**
```bash
cd terraform
terraform destroy -target=aws_acm_certificate_validation.wildcard -auto-approve
```

### **Step 2: Import the existing certificate**
```bash
terraform import aws_acm_certificate.wildcard arn:aws:acm:us-east-1:[REDACTED]:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f
```

### **Step 3: Check certificate status**
```bash
aws acm describe-certificate --certificate-arn "arn:aws:acm:us-east-1:[REDACTED]:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f" --region us-east-1 --query 'Certificate.{Status:Status,ValidationStatus:DomainValidationOptions[0].ValidationStatus}'
```

### **Step 4: If certificate is already validated, skip validation**
If the certificate shows `Status: ISSUED`, then you can skip the validation step by commenting out the validation resource in your Terraform file.

### **Step 5: Apply the rest of the infrastructure**
```bash
terraform plan
terraform apply
```

## 🔧 **Alternative: Skip Certificate Validation**

If the certificate is already validated, you can modify your Terraform to skip validation:

1. **Comment out the validation resource** in `domain-namecheap.tf`:
   ```hcl
   # resource "aws_acm_certificate_validation" "wildcard" {
   #   provider = aws.us_east_1
   #   
   #   certificate_arn         = aws_acm_certificate.wildcard.arn
   #   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
   #
   #   timeouts {
   #     create = "10m"
   #   }
   # }
   ```

2. **Update the CloudFront distribution** to use the certificate directly:
   ```hcl
   viewer_certificate {
     acm_certificate_arn      = aws_acm_certificate.wildcard.arn
     ssl_support_method       = "sni-only"
     minimum_protocol_version = "TLSv1.2_2021"
   }
   ```

3. **Apply the changes**:
   ```bash
   terraform apply
   ```

## 📋 **Quick Commands Summary**

```bash
# Fix the state
terraform destroy -target=aws_acm_certificate_validation.wildcard -auto-approve
terraform import aws_acm_certificate.wildcard arn:aws:acm:us-east-1:[REDACTED]:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f

# Check if certificate is already valid
aws acm describe-certificate --certificate-arn "arn:aws:acm:us-east-1:[REDACTED]:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f" --region us-east-1 --query 'Certificate.Status'

# If certificate is ISSUED, apply the rest
terraform apply
```
