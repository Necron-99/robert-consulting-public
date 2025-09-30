# Quick Fix for CloudFront Certificate Error

## 🚨 **Immediate Solution**

The error occurs because CloudFront can't use a certificate that's still in `PENDING_VALIDATION` status. Here's the quick fix:

### **Option 1: Deploy with Default Certificate First**

```bash
cd terraform

# 1. Apply with the current configuration (using default certificate)
terraform apply

# 2. Get the nameservers
terraform output name_servers

# 3. Update your domain nameservers at your registrar
# 4. Wait for DNS propagation (5-60 minutes)
# 5. Test the site works with default certificate
```

### **Option 2: Validate Certificate First**

```bash
# 1. Get the validation records
aws acm describe-certificate --certificate-arn "arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f" --region us-east-1 --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,RecordName:ResourceRecord.Name,RecordValue:ResourceRecord.Value,RecordType:ResourceRecord.Type}' --output table

# 2. Add these CNAME records to your DNS provider
# 3. Wait 5-10 minutes for DNS propagation
# 4. Check certificate status
aws acm describe-certificate --certificate-arn "arn:aws:acm:us-east-1:228480945348:certificate/cefe26a0-b4b5-478a-bd79-6cdefe8bf45f" --region us-east-1 --query 'Certificate.Status'

# 5. Once certificate shows "ISSUED", update CloudFront to use it
```

### **Option 3: Use Automated Script**

```bash
# For Linux/Mac
chmod +x terraform/fix-certificate-and-deploy.sh
./terraform/fix-certificate-and-deploy.sh

# For Windows PowerShell
.\terraform\fix-certificate-and-deploy.ps1
```

## 📋 **Recommended Approach**

1. **Deploy with default certificate first** (Option 1)
2. **Get your site working** with the new domain
3. **Validate the certificate manually** (Option 2)
4. **Update CloudFront** to use the validated certificate later

This approach gets your site working immediately while you handle certificate validation separately.
