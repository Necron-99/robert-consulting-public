# AWS Resource Cleanup Plan

## Overview
This document outlines a comprehensive plan to clean up orphaned AWS resources identified during the audit. **All actions require explicit approval before execution.**

## 🔴 Critical Orphans (Immediate Action Required)

### 1. CloudFront Distribution E1JE597A8ZZ547
- **Type**: Duplicate admin site distribution
- **Status**: Currently disabling
- **Action**: Delete once fully disabled
- **Verification**: ✅ Already identified and script created
- **Cost Impact**: $0.85/month per distribution

### 2. Route53 Hosted Zone Z0219036XF42XEMQOJ4
- **Type**: Old robertconsulting.net zone
- **Status**: Not managed by Terraform
- **Action**: Delete after confirming no critical records
- **Verification**: ✅ Already identified as inactive
- **Cost Impact**: $0.50/month per hosted zone

## 🟡 High Priority Cleanup (Significant Cost Savings)

### 3. S3 Buckets (Estimated $5-15/month savings)

#### 3.1 CDK Practice Buckets
- **cdk-hnb659fds-assets-228480945348-us-east-1**
  - **Purpose**: CDK deployment assets
  - **Verification Needed**: Check if CDK stack still exists
  - **Action**: Delete if CDK stack is removed

- **cdk-practice-20250703**
  - **Purpose**: Practice CDK deployment
  - **Verification Needed**: Confirm it's practice/test data
  - **Action**: Delete if confirmed as practice

#### 3.2 Old Admin Site Buckets
- **rc-admin-site-1f75fc**
- **rc-admin-site-20251010-38fa9c**
- **rc-admin-site-43d11d**
  - **Purpose**: Old admin site deployments
  - **Verification Needed**: Confirm current admin site is in different bucket
  - **Action**: Delete if confirmed as old deployments

#### 3.3 Old Website Backup
- **robert-consulting-website-2024-bd900b02**
  - **Purpose**: 2024 website backup
  - **Verification Needed**: Confirm current website is in different bucket
  - **Action**: Delete if confirmed as old backup

### 4. Lambda Functions (Estimated $2-5/month savings)

#### 4.1 Duplicate Admin Auth Functions
- **rc-admin-auth-5c4da7d9**
- **rc-admin-auth-aa3d6334**
  - **Purpose**: Admin authentication (duplicates)
  - **Verification Needed**: Check which one is currently used by CloudFront
  - **Action**: Delete unused duplicate

### 5. DynamoDB Tables (Estimated $1-3/month savings)

#### 5.1 Duplicate Admin Tables
- **rc-admin-audit-5c4da7d9** / **rc-admin-audit-aa3d6334**
- **rc-admin-sessions-5c4da7d9** / **rc-admin-sessions-aa3d6334**
  - **Purpose**: Admin session and audit logging (duplicates)
  - **Verification Needed**: Check which tables are actively used
  - **Action**: Delete unused duplicates

## 🟠 Medium Priority Cleanup

### 6. WAF Resources (Estimated $5-10/month savings)

#### 6.1 Duplicate Web ACLs
- **rc-admin-enhanced-waf-5c4da7d9** / **rc-admin-enhanced-waf-aa3d6334**
- **rc-main-site-waf-398fb6** / **rc-main-site-waf-5e3ba1**
  - **Purpose**: Web Application Firewall rules (duplicates)
  - **Verification Needed**: Check which ACLs are attached to CloudFront distributions
  - **Action**: Delete unused duplicates

### 7. IAM Roles (No direct cost, but security cleanup)

#### 7.1 Duplicate Admin Roles
- **rc-admin-auth-role-5c4da7d9** / **rc-admin-auth-role-aa3d6334**
  - **Purpose**: Lambda execution roles (duplicates)
  - **Verification Needed**: Check which role is used by active Lambda functions
  - **Action**: Delete unused duplicate

### 8. Secrets Manager (Estimated $0.40/month per secret)

#### 8.1 Duplicate Admin Secrets
- **rc-admin-security-5c4da7d9** / **rc-admin-security-aa3d6334**
  - **Purpose**: Admin security configuration (duplicates)
  - **Verification Needed**: Check which secret is referenced by active resources
  - **Action**: Delete unused duplicate

## 🟢 Low Priority Cleanup

### 9. API Gateway (Estimated $3.50/month per API)

#### 9.1 Duplicate APIs
- Multiple APIs with different IDs but same names
  - **Verification Needed**: Check which APIs are actively used
  - **Action**: Delete unused duplicates

### 10. CloudFront Functions (No direct cost)

#### 10.1 Duplicate Functions
- Multiple functions with same names
  - **Verification Needed**: Check which functions are deployed
  - **Action**: Delete unused duplicates

### 11. ACM Certificates (No direct cost)

#### 11.1 Duplicate Certificates
- Duplicate certificates for same domains
  - **Verification Needed**: Check which certificates are in use
  - **Action**: Delete unused duplicates

### 12. CloudWatch Log Groups (Estimated $0.50/month per log group)

#### 12.1 Unused Log Groups
- **/aws/lambda/aws-scheduler** (unused)
- Duplicate admin function log groups
  - **Verification Needed**: Check if log groups are actively logging
  - **Action**: Delete unused log groups

### 13. SES Configuration Sets (No direct cost)

#### 13.1 Unused Configuration Sets
- **my-first-configuration-set**
  - **Verification Needed**: Check if configuration set is used
  - **Action**: Delete if unused

## 📋 Cleanup Execution Plan

### Phase 1: Verification (No Actions)
1. Verify each resource's current usage
2. Confirm which resources are duplicates
3. Document dependencies

### Phase 2: High Priority Cleanup
1. Delete confirmed orphaned S3 buckets
2. Delete duplicate Lambda functions
3. Delete duplicate DynamoDB tables

### Phase 3: Medium Priority Cleanup
1. Delete duplicate WAF resources
2. Delete duplicate IAM roles
3. Delete duplicate secrets

### Phase 4: Low Priority Cleanup
1. Delete duplicate API Gateway endpoints
2. Delete duplicate CloudFront functions
3. Delete duplicate ACM certificates
4. Delete unused CloudWatch log groups
5. Delete unused SES configuration sets

## 💰 Total Estimated Monthly Savings
- **High Priority**: $8-23/month
- **Medium Priority**: $5-10/month
- **Low Priority**: $1-2/month
- **Total**: $14-35/month

## ⚠️ Safety Measures
1. **Backup Verification**: All current resources are backed up in Terraform state
2. **Dependency Checking**: Each resource will be verified for dependencies before deletion
3. **Rollback Plan**: Terraform can recreate any accidentally deleted resources
4. **Approval Required**: Each phase requires explicit approval before execution

## 🎯 Next Steps
1. **Review this plan** and approve the approach
2. **Approve Phase 1** (verification only, no deletions)
3. **Review verification results** and approve specific deletions
4. **Execute approved cleanup** in phases

---
**Status**: Awaiting approval to begin Phase 1 (verification)
**Created**: $(date)
**Estimated Total Savings**: $14-35/month
