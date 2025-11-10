# AWS Resource Catalog & Tagging Solution Proposal

**Date:** November 10, 2025  
**Goal:** Catalogue and verify utility of AWS resources, ensure proper tagging, identify unused resources

## Problem Statement

- Unclear which AWS resources are actively used vs. orphaned
- Empty S3 buckets and redundant CloudFront distributions create clutter
- Difficult to identify which resources are causing issues
- Need up-to-date catalogue in a cheap managed AWS service
- Resources need proper tagging for organization

## Current State

Based on Terraform audit:
- Multiple S3 buckets
- Multiple CloudFront distributions  
- Multiple Lambda functions
- Some resources may be orphaned or unused
- Tagging may be inconsistent

## Proposed Solutions

### Solution 1: AWS Resource Groups + Tag Editor + Custom Lambda Auditor

**Architecture:**
- AWS Resource Groups for organization and filtering
- Tag Editor for bulk tagging operations
- Custom Lambda function (scheduled daily) to:
  - Scan all resources
  - Check utilization (S3 bucket size, CloudFront requests, Lambda invocations)
  - Store results in DynamoDB
  - Generate reports
- CloudWatch Dashboard for visualization

**Cost:** ~$0.50-2.00/month
- Lambda: Free tier (1M requests/month)
- DynamoDB: On-demand pricing (~$1.25/million reads, $1.25/million writes)
- CloudWatch: Free tier (10 custom metrics)
- Resource Groups: Free
- Tag Editor: Free

**Pros:**
- ✅ Fully customizable
- ✅ Can check actual utilization (not just existence)
- ✅ Can identify empty buckets, unused distributions
- ✅ Can generate custom reports
- ✅ Integrates with existing infrastructure
- ✅ Very low cost
- ✅ Can add custom business logic

**Cons:**
- ⚠️ Requires development/maintenance
- ⚠️ Need to handle IAM permissions for all resource types
- ⚠️ Lambda execution time limits (15 min max)

---

### Solution 2: AWS Config + Resource Groups

**Architecture:**
- AWS Config for compliance and resource tracking
- Config Rules to check for proper tagging
- Resource Groups for organization
- Config Aggregator for multi-region view
- S3 bucket for Config snapshots

**Cost:** ~$2.00-5.00/month
- Config: $0.003 per configuration item recorded
- Config Rules: $0.001 per rule evaluation
- S3 storage: Minimal for snapshots

**Pros:**
- ✅ Native AWS service, well-supported
- ✅ Automatic resource tracking
- ✅ Compliance checking built-in
- ✅ Historical tracking (resource changes over time)
- ✅ Can detect configuration drift
- ✅ Integrates with other AWS services

**Cons:**
- ⚠️ More expensive than custom solution
- ⚠️ Doesn't check utilization (only existence/config)
- ⚠️ Can be complex to set up
- ⚠️ May record more than needed

---

### Solution 3: AWS Systems Manager Inventory + Custom Scripts

**Architecture:**
- SSM Inventory for resource discovery
- Custom scripts to analyze inventory
- DynamoDB for storing analysis results
- CloudWatch Events to trigger periodic scans

**Cost:** ~$0.25-1.00/month
- SSM Inventory: Free (for EC2/on-premises, but can be extended)
- DynamoDB: On-demand pricing
- CloudWatch Events: Free tier

**Pros:**
- ✅ Very low cost
- ✅ Good for EC2/on-premises resources
- ✅ Can be extended with custom collectors

**Cons:**
- ⚠️ Primarily designed for EC2/on-premises
- ⚠️ Limited for serverless resources (S3, Lambda, CloudFront)
- ⚠️ Requires custom development for our use case
- ⚠️ May not capture all resource types we need

---

### Solution 4: Hybrid: AWS Resource Groups + Custom Lambda + DynamoDB + Cost Explorer Tags

**Architecture:**
- Resource Groups for organization
- Custom Lambda function (daily) to:
  - Use AWS Resource Groups Tagging API to get all resources
  - Check utilization metrics from CloudWatch
  - Store in DynamoDB with metadata
- DynamoDB table for resource catalog
- CloudWatch Dashboard for visualization
- Cost Explorer tags for cost attribution
- S3 bucket for archived reports

**Cost:** ~$0.50-1.50/month
- Lambda: Free tier
- DynamoDB: On-demand (~$1.25/million operations)
- CloudWatch: Free tier
- S3: Minimal for reports
- Resource Groups: Free

**Pros:**
- ✅ Best of both worlds (native + custom)
- ✅ Checks actual utilization
- ✅ Proper tagging enforcement
- ✅ Cost-effective
- ✅ Can identify unused resources
- ✅ Historical tracking in DynamoDB
- ✅ Can generate reports

**Cons:**
- ⚠️ Requires some development
- ⚠️ Need to maintain Lambda function
- ⚠️ IAM permissions complexity

---

## Recommendation: Solution 4 (Hybrid Approach)

**Why:**
1. **Cost-effective**: ~$0.50-1.50/month
2. **Comprehensive**: Checks both existence and utilization
3. **Flexible**: Can add custom business logic
4. **Maintainable**: Uses managed services where possible
5. **Actionable**: Can identify empty buckets, unused distributions
6. **Tagging**: Enforces proper tagging standards

## Implementation Plan (if approved)

### Phase 1: Resource Discovery & Catalog
1. Create DynamoDB table for resource catalog
2. Create Lambda function to scan resources
3. Use Resource Groups Tagging API to discover all resources
4. Store resource metadata in DynamoDB

### Phase 2: Utilization Analysis
1. Query CloudWatch metrics for each resource
2. Check S3 bucket sizes and object counts
3. Check CloudFront request counts
4. Check Lambda invocation counts
5. Mark resources as "active", "inactive", or "unused"

### Phase 3: Tagging Enforcement
1. Define tagging standards
2. Create Lambda function to check/enforce tags
3. Generate reports for untagged resources
4. Bulk tagging via Tag Editor

### Phase 4: Reporting & Dashboard
1. Create CloudWatch Dashboard
2. Generate weekly reports
3. Alert on orphaned resources
4. Export to S3 for archival

## Tagging Standards

Proposed tags:
- `Project`: Main project name (e.g., "Robert Consulting")
- `Environment`: production, staging, development
- `ManagedBy`: terraform, manual, other
- `Purpose`: Brief description of resource purpose
- `LastUsed`: Date when resource was last accessed
- `Status`: active, inactive, unused, deprecated
- `CostCenter`: For cost allocation

## Success Metrics

- All resources properly tagged
- Zero untagged resources
- Catalog updated daily
- Unused resources identified and cleaned up
- Cost attribution clear

## Next Steps

1. Review and approve solution
2. Define tagging standards
3. Implement Phase 1 (Resource Discovery)
4. Test with current resources
5. Roll out to production

