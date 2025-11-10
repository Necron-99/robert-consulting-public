# Resource Cataloger Lambda Function

## Purpose

Discovers, catalogs, and tracks all AWS resources with utilization metrics and tagging validation.

## Safety Features

⚠️ **NEVER DELETES RESOURCES AUTOMATICALLY**

- All operations are read-only by default
- Dry-run mode enabled by default
- Requires explicit manual approval for any destructive actions
- Multiple verification checks before any deletion
- Detailed logging of all operations

## Features

1. **Resource Discovery**
   - Uses AWS Resource Groups Tagging API
   - Discovers tagged and untagged resources
   - Supports: S3, CloudFront, Lambda, API Gateway, Route53, WAF

2. **Utilization Tracking**
   - S3: Bucket size and object count
   - CloudFront: Request counts (last 7 days)
   - Lambda: Invocation counts (last 30 days)

3. **Tagging Validation**
   - Checks for required tags: Project, Environment, ManagedBy, Purpose
   - Identifies missing tags
   - Marks resources as "needs-tagging"

4. **Status Determination**
   - `active`: Resource is used and properly tagged
   - `unused`: Resource has no utilization
   - `needs-tagging`: Missing required tags
   - `needs-attention`: Requires manual review

## Environment Variables

- `CATALOG_TABLE_NAME`: DynamoDB table name (required)
- `DRY_RUN`: Set to "true" for dry-run mode (default: true)
- `REQUIRE_APPROVAL`: Set to "true" to require approval (default: true)

## Usage

The function runs automatically daily at 2 AM UTC via CloudWatch Events.

To run manually:
```bash
aws lambda invoke --function-name robert-consulting-resource-cataloger response.json
```

## Output

Results are stored in DynamoDB table with the following structure:
- `resource_arn` (primary key)
- `resource_type`
- `resource_name`
- `status`
- `tags` (JSON)
- `utilization` (JSON)
- `tag_validation` (JSON)
- `last_updated`
- `discovered_at`
- `region`

