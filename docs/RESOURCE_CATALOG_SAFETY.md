# Resource Catalog Safety Guidelines

## ⚠️ CRITICAL SAFETY RULES

**NEVER DELETE RESOURCES AUTOMATICALLY**

All resource deletions require:
1. ✅ Explicit manual approval
2. ✅ Multiple confirmation steps
3. ✅ Resource ARN verification
4. ✅ Dry-run mode by default
5. ✅ Detailed logging

## Safety Features Implemented

### 1. Dry-Run Mode (Default)
- All operations start in dry-run mode
- Set `DRY_RUN=false` only when explicitly needed
- Dry-run shows what would be deleted without actually deleting

### 2. Approval Workflow
The `resource-cleanup-approval.sh` script requires:
- Type 'DELETE' to proceed
- Type 'YES' to confirm
- Provide explicit list of ARNs to delete
- Each step can be cancelled

### 3. Resource Verification
Before deletion, verify:
- Resource is truly unused (check utilization metrics)
- No dependencies exist
- Backups are available if needed
- Resource is not in Terraform state (if managed by Terraform)

### 4. Catalog Tracking
- All resources are cataloged in DynamoDB
- Deletion status is tracked
- Historical records maintained
- Can restore from catalog if needed

## Usage

### Daily Automatic Scan
The Lambda function runs daily at 2 AM UTC and:
- Discovers all resources
- Checks utilization
- Validates tags
- Updates catalog
- **NEVER deletes anything**

### Manual Cleanup (Requires Approval)
```bash
# Step 1: Review unused resources
aws dynamodb query \
  --table-name robert-consulting-resource-catalog \
  --index-name status-index \
  --key-condition-expression "status = :status" \
  --expression-attribute-values '{":status":{"S":"unused"}}'

# Step 2: Run approval script (dry-run first)
DRY_RUN=true ./scripts/resource-cleanup-approval.sh

# Step 3: If satisfied, run with approval
DRY_RUN=false ./scripts/resource-cleanup-approval.sh
```

## Resource Status Values

- `active`: Resource is used and properly tagged
- `unused`: No utilization detected (requires review)
- `needs-tagging`: Missing required tags
- `needs-attention`: Requires manual review
- `deleted`: Resource has been deleted (historical record)

## Required Tags

All resources should have:
- `Project`: Main project name
- `Environment`: production, staging, development
- `ManagedBy`: terraform, manual, other
- `Purpose`: Brief description

## Best Practices

1. **Review Before Action**: Always review the catalog before taking action
2. **Start with Tagging**: Tag resources before considering deletion
3. **Check Dependencies**: Verify no other resources depend on it
4. **Backup First**: Create backups if data might be needed
5. **Document Decisions**: Record why resources were deleted
6. **Monitor Alerts**: Respond to SNS alerts for untagged/unused resources

## Emergency Procedures

If a resource is deleted by mistake:
1. Check DynamoDB catalog for resource details
2. Check CloudTrail logs for deletion event
3. Restore from backup if available
4. Recreate via Terraform if managed
5. Update catalog status

## Cost Estimate

- DynamoDB: ~$0.50/month (on-demand, minimal usage)
- Lambda: Free tier (1M requests/month)
- CloudWatch: Free tier (10 custom metrics)
- SNS: Free tier (100 notifications/month)
- **Total: ~$0.50-1.50/month**

