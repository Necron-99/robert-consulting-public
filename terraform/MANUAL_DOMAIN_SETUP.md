# Manual Domain Setup Guide for robertconsulting.net

## 🎯 **The Problem**
You just purchased `robertconsulting.net` from AWS, but the domain doesn't resolve because the nameservers haven't been configured yet.

## 🔧 **Solution: Configure Nameservers**

### **Step 1: Get Your Route 53 Nameservers**
```bash
cd terraform
terraform output name_servers
```

You should see something like:
```
[
  "ns-1359.awsdns-41.org",
  "ns-170.awsdns-21.com", 
  "ns-1850.awsdns-39.co.uk",
  "ns-874.awsdns-45.net"
]
```

### **Step 2: Update Domain Nameservers**

**Option A: Using AWS CLI (Recommended)**
```bash
# Get the nameservers
NAMESERVERS=$(terraform output -json name_servers | jq -r '.[]' | tr '\n' ' ')

# Update the domain
aws route53domains update-domain-nameservers \
    --domain-name robertconsulting.net \
    --nameservers Name=$NAMESERVERS \
    --region us-east-1
```

**Option B: Using AWS Console**
1. Go to [Route 53 Console](https://console.aws.amazon.com/route53/)
2. Click "Registered domains"
3. Click on `robertconsulting.net`
4. Click "Add or edit name servers"
5. Replace the current nameservers with:
   - `ns-1359.awsdns-41.org`
   - `ns-170.awsdns-21.com`
   - `ns-1850.awsdns-39.co.uk`
   - `ns-874.awsdns-45.net`
6. Click "Update"

### **Step 3: Wait for DNS Propagation**
- **Initial propagation**: 5-15 minutes
- **Full propagation**: 24-48 hours
- **Test periodically**: `nslookup robertconsulting.net`

### **Step 4: Verify Domain is Working**
```bash
# Test nameservers
nslookup -type=NS robertconsulting.net 8.8.8.8

# Test domain resolution
nslookup robertconsulting.net

# Test website
curl -I https://robertconsulting.net
```

## 🚀 **After Domain is Working**

### **Deploy SES Configuration**
```bash
terraform apply
```

### **Test Email Functionality**
```bash
./test-email.sh
```

## 🔍 **Troubleshooting**

### **If nameservers don't update:**
1. Check domain registration status
2. Verify you have permissions to modify nameservers
3. Try updating via AWS Console instead of CLI

### **If domain still doesn't resolve:**
1. Wait longer (up to 48 hours)
2. Check different DNS servers (8.8.8.8, 1.1.1.1)
3. Clear your local DNS cache

### **Check domain status:**
```bash
aws route53domains get-domain-detail --domain-name robertconsulting.net --region us-east-1
```

## 📋 **Expected Timeline**
- **Nameserver update**: 2-5 minutes
- **DNS propagation**: 5-60 minutes  
- **Full functionality**: 1-24 hours

**Once the domain resolves, your website and email will work perfectly!**
