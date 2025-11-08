# Cost Guardrails Proposal

**Date**: January 2025  
**Purpose**: Prevent excessive spending from AWS API calls (e.g., $100/day from Cost Explorer or CloudWatch API calls)

---

## Current Risk Assessment

### High-Risk Areas Identified:
1. **CloudWatch GetMetricDataCommand** - Can cost $0.01 per 1,000 metrics queried
   - Dashboard API Lambda makes multiple metric queries per invocation
   - If called frequently, costs can escalate quickly

2. **Multiple AWS Service API Calls** - terraform-stats-refresher Lambda
   - Route53, S3, CloudFront, WAF, API Gateway, CloudWatch, Lambda, IAM, DynamoDB
   - Each API call has potential costs, especially if rate limits are exceeded

3. **Lambda Invocation Costs** - No rate limiting on Lambda invocations themselves
   - If dashboard is refreshed frequently, Lambda costs + API costs compound

4. **GitHub API Calls** - While free, excessive calls could trigger rate limits causing retries

### Existing Protections:
- ✅ CloudWatch alarms for cost thresholds ($15/month, $5/service)
- ✅ Cost Explorer API disabled (static data used)
- ✅ WAF rate limiting for HTTP requests
- ❌ No AWS Budgets configured
- ❌ No API call rate limiting in Lambda functions
- ❌ No automatic cost-based throttling

---

## Solution 1: AWS Budgets with Automatic Actions

### Overview
Configure AWS Budgets to monitor daily costs and automatically take action when thresholds are exceeded.

### Implementation:
```hcl
# AWS Budget for daily cost monitoring
resource "aws_budgets_budget" "daily_cost_guardrail" {
  name              = "daily-cost-guardrail"
  budget_type       = "COST"
  limit_amount      = "10"  # $10/day threshold
  limit_unit        = "USD"
  time_period_start = "2025-01-01_00:00"
  time_unit         = "DAILY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 50  # Alert at 50% ($5)
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["rsbailey@necron99.org"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80  # Alert at 80% ($8)
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["rsbailey@necron99.org"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100  # Alert at 100% ($10)
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = ["rsbailey@necron99.org"]
  }
}

# Budget action to disable Lambda functions if threshold exceeded
resource "aws_budgets_budget_action" "disable_lambdas" {
  budget_name = aws_budgets_budget.daily_cost_guardrail.name
  action_type = "APPLY_IAM_POLICY"
  
  action_threshold {
    action_threshold_value = 100  # Trigger at 100% of budget
    action_threshold_type  = "PERCENTAGE"
  }

  definition {
    iam_action_definition {
      policy_arn = aws_iam_policy.lambda_disable_policy.arn
      roles      = [aws_iam_role.budget_action_role.name]
    }
  }

  approval_model = "AUTOMATIC"
  execution_role_arn = aws_iam_role.budget_action_role.arn
  notification_type = "ACTUAL"
}

# IAM policy to deny Lambda invocations
resource "aws_iam_policy" "lambda_disable_policy" {
  name = "disable-lambdas-on-budget-exceeded"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Deny"
      Action = [
        "lambda:InvokeFunction"
      ]
      Resource = [
        "arn:aws:lambda:*:*:function:robert-consulting-dashboard-api",
        "arn:aws:lambda:*:*:function:robert-consulting-stats-refresher",
        "arn:aws:lambda:*:*:function:robert-consulting-terraform-stats-refresher"
      ]
    }]
  })
}
```

### Pros:
✅ **Cost**: 
- AWS Budgets: **FREE** (no additional cost)
- Immediate cost protection at infrastructure level
- Prevents runaway costs before they occur

✅ **Security**:
- Automatic enforcement (no human intervention needed)
- Can disable specific services automatically
- Works at AWS account level

✅ **Maintainability**:
- Simple Terraform configuration
- AWS-managed service (no code to maintain)
- Clear alerts at 50%, 80%, 100% thresholds

### Cons:
❌ **Cost**: 
- Budget actions require IAM role setup (one-time effort)
- May be too aggressive (disables entire functions)

❌ **Security**:
- Budget actions can be disruptive if misconfigured
- Requires careful IAM policy design to avoid breaking legitimate operations

❌ **Maintainability**:
- Budget actions are irreversible until manually re-enabled
- Need to manually re-enable services after investigation
- May require additional monitoring to understand what triggered the action

---

## Solution 2: Lambda-Based API Call Rate Limiting & Cost Tracking

### Overview
Implement application-level rate limiting and cost tracking within Lambda functions to prevent excessive API calls.

### Implementation:
```javascript
// Shared utility: api-rate-limiter.js
const { DynamoDBClient, PutItemCommand, GetItemCommand } = require('@aws-sdk/client-dynamodb');

const dynamodb = new DynamoDBClient({ region: 'us-east-1' });
const RATE_LIMIT_TABLE = 'api-rate-limits';
const COST_TRACKER_TABLE = 'api-cost-tracking';

// Rate limiting configuration
const RATE_LIMITS = {
  'cloudwatch:GetMetricData': { maxCalls: 100, windowMs: 3600000 }, // 100/hour
  'route53:ListHostedZones': { maxCalls: 10, windowMs: 3600000 },   // 10/hour
  's3:ListBuckets': { maxCalls: 20, windowMs: 3600000 },             // 20/hour
  'cost-explorer:GetCostAndUsage': { maxCalls: 0, windowMs: 3600000 } // BLOCKED
};

// Cost tracking (estimated)
const API_COSTS = {
  'cloudwatch:GetMetricData': 0.00001,  // $0.01 per 1,000 calls
  'route53:ListHostedZones': 0.0005,     // $0.50 per 1,000 calls
  's3:ListBuckets': 0.0005,              // $0.50 per 1,000 calls
};

async function checkRateLimit(apiCall) {
  const limit = RATE_LIMITS[apiCall];
  if (!limit) return { allowed: true };
  
  if (limit.maxCalls === 0) {
    return { allowed: false, reason: 'API call blocked by policy' };
  }

  const now = Date.now();
  const windowStart = now - limit.windowMs;
  const key = `${apiCall}:${Math.floor(windowStart / limit.windowMs)}`;

  try {
    const result = await dynamodb.send(new GetItemCommand({
      TableName: RATE_LIMIT_TABLE,
      Key: { apiCall: { S: key } }
    }));

    const currentCount = result.Item ? parseInt(result.Item.count.N) : 0;
    
    if (currentCount >= limit.maxCalls) {
      return { 
        allowed: false, 
        reason: `Rate limit exceeded: ${currentCount}/${limit.maxCalls} calls in window` 
      };
    }

    // Increment counter
    await dynamodb.send(new PutItemCommand({
      TableName: RATE_LIMIT_TABLE,
      Item: {
        apiCall: { S: key },
        count: { N: String(currentCount + 1) },
        ttl: { N: String(Math.floor(now / 1000) + (limit.windowMs / 1000)) }
      }
    }));

    // Track cost
    await trackAPICost(apiCall);

    return { allowed: true, remaining: limit.maxCalls - (currentCount + 1) };
  } catch (error) {
    console.error('Rate limit check failed:', error);
    // Fail open for availability, but log the error
    return { allowed: true, warning: 'Rate limit check failed' };
  }
}

async function trackAPICost(apiCall) {
  const cost = API_COSTS[apiCall] || 0;
  if (cost === 0) return;

  const today = new Date().toISOString().split('T')[0];
  const key = `cost:${today}`;

  try {
    const result = await dynamodb.send(new GetItemCommand({
      TableName: COST_TRACKER_TABLE,
      Key: { date: { S: key } }
    }));

    const currentCost = result.Item ? parseFloat(result.Item.cost.N) : 0;
    const newCost = currentCost + cost;

    // Alert if daily cost exceeds threshold
    if (newCost > 5.0) { // $5/day threshold
      await sendCostAlert(newCost, today);
    }

    await dynamodb.send(new PutItemCommand({
      TableName: COST_TRACKER_TABLE,
      Item: {
        date: { S: key },
        cost: { N: String(newCost) },
        lastUpdated: { S: new Date().toISOString() },
        ttl: { N: String(Math.floor(Date.now() / 1000) + 86400 * 7)) } // 7 days retention
      }
    }));
  } catch (error) {
    console.error('Cost tracking failed:', error);
  }
}

async function sendCostAlert(cost, date) {
  // Send SNS notification
  const sns = new SNSClient({ region: 'us-east-1' });
  await sns.send(new PublishCommand({
    TopicArn: process.env.COST_ALERT_TOPIC_ARN,
    Subject: `⚠️ High API Cost Alert: $${cost.toFixed(2)} on ${date}`,
    Message: `API costs have exceeded $5.00 threshold. Current cost: $${cost.toFixed(2)}`
  }));
}

module.exports = { checkRateLimit, trackAPICost };
```

### Terraform Configuration:
```hcl
# DynamoDB table for rate limiting
resource "aws_dynamodb_table" "api_rate_limits" {
  name           = "api-rate-limits"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "apiCall"

  attribute {
    name = "apiCall"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "API Rate Limits"
    Purpose = "cost-control"
  }
}

# DynamoDB table for cost tracking
resource "aws_dynamodb_table" "api_cost_tracking" {
  name           = "api-cost-tracking"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "date"

  attribute {
    name = "date"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name = "API Cost Tracking"
    Purpose = "cost-control"
  }
}
```

### Pros:
✅ **Cost**: 
- DynamoDB on-demand: ~$0.25 per million requests (very low)
- Prevents expensive API calls before they happen
- Cost tracking provides visibility into actual spending

✅ **Security**:
- Application-level control (can be more granular than AWS-level)
- Can block specific API calls (e.g., Cost Explorer)
- Fail-open design maintains availability

✅ **Maintainability**:
- Code-based solution (easy to modify limits)
- Can adjust limits per API call type
- Provides detailed logging and cost tracking
- Can be tested and versioned with code

### Cons:
❌ **Cost**: 
- DynamoDB costs (minimal, but not zero)
- Requires code changes to all Lambda functions
- Additional Lambda execution time (minimal overhead)

❌ **Security**:
- Fail-open design means errors don't block (could allow costs if DynamoDB fails)
- Requires careful implementation to avoid bypassing checks
- Code-based solution requires code review for security

❌ **Maintainability**:
- Requires code changes and testing
- Need to maintain rate limit configuration
- DynamoDB tables need monitoring
- More complex than AWS-native solutions

---

## Solution 3: CloudWatch Cost Anomaly Detection + Lambda Throttling

### Overview
Use AWS Cost Anomaly Detection to identify unusual spending patterns and automatically throttle Lambda functions via EventBridge rules.

### Implementation:
```hcl
# Cost Anomaly Detection
resource "aws_ce_anomaly_detector" "api_cost_anomaly" {
  name              = "api-cost-anomaly-detector"
  anomaly_detector_type = "STANDARD"
  
  specification = jsonencode({
    MonitorType = "DIMENSIONAL"
    Dimension   = "SERVICE"
  })
}

# SNS topic for anomaly alerts
resource "aws_sns_topic" "cost_anomaly_alerts" {
  name = "cost-anomaly-alerts"
}

resource "aws_sns_topic_subscription" "cost_anomaly_email" {
  topic_arn = aws_sns_topic.cost_anomaly_alerts.arn
  protocol  = "email"
  endpoint  = "rsbailey@necron99.org"
}

# EventBridge rule to trigger on cost anomaly
resource "aws_cloudwatch_event_rule" "cost_anomaly_trigger" {
  name        = "cost-anomaly-trigger"
  description = "Trigger when cost anomaly detected"

  event_pattern = jsonencode({
    source      = ["aws.cost-management"]
    detail-type = ["Cost Anomaly Detection"]
  })
}

# Lambda function to throttle APIs on anomaly
resource "aws_lambda_function" "cost_throttler" {
  filename      = "cost-throttler.zip"
  function_name = "cost-throttler"
  role          = aws_iam_role.cost_throttler_role.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  environment {
    variables = {
      THROTTLE_PERCENTAGE = "50"  # Reduce Lambda concurrency by 50%
    }
  }
}

# Lambda code (cost-throttler/index.js)
# Updates Lambda reserved concurrency to throttle invocations
const { LambdaClient, PutFunctionConcurrencyCommand, GetFunctionCommand } = require('@aws-sdk/client-lambda');

const lambda = new LambdaClient({ region: 'us-east-1' });
const TARGET_FUNCTIONS = [
  'robert-consulting-dashboard-api',
  'robert-consulting-stats-refresher',
  'robert-consulting-terraform-stats-refresher'
];

exports.handler = async (event) => {
  const anomaly = JSON.parse(event.detail);
  
  if (anomaly.AnomalyScore > 0.7) { // High confidence anomaly
    console.log(`Cost anomaly detected: ${anomaly.AnomalyDetails}`);
    
    // Throttle Lambda functions
    for (const functionName of TARGET_FUNCTIONS) {
      try {
        const func = await lambda.send(new GetFunctionCommand({ FunctionName: functionName }));
        const currentConcurrency = func.Concurrency?.ReservedConcurrentExecutions || 100;
        const newConcurrency = Math.max(1, Math.floor(currentConcurrency * 0.5)); // 50% reduction
        
        await lambda.send(new PutFunctionConcurrencyCommand({
          FunctionName: functionName,
          ReservedConcurrentExecutions: newConcurrency
        }));
        
        console.log(`Throttled ${functionName} to ${newConcurrency} concurrent executions`);
      } catch (error) {
        console.error(`Failed to throttle ${functionName}:`, error);
      }
    }
  }
};
```

### Pros:
✅ **Cost**: 
- Cost Anomaly Detection: **FREE** (AWS service)
- Automatic detection of unusual patterns
- Can identify specific services causing issues

✅ **Security**:
- AWS-managed anomaly detection (uses ML)
- Automatic response via EventBridge
- Can be configured to be less disruptive than full shutdown

✅ **Maintainability**:
- AWS-native solution (no custom code for detection)
- EventBridge integration is standard AWS pattern
- Can add more sophisticated throttling logic over time

### Cons:
❌ **Cost**: 
- Cost Anomaly Detection requires 2 weeks of data to train
- Lambda throttler function has execution costs
- May not catch issues fast enough (anomaly detection has delay)

❌ **Security**:
- Anomaly detection may have false positives
- Throttling may not be sufficient for runaway costs
- Requires careful tuning of anomaly thresholds

❌ **Maintainability**:
- More complex setup (EventBridge + Lambda)
- Anomaly detection needs time to learn normal patterns
- May require adjustment of anomaly sensitivity
- Throttling logic needs to be maintained

---

## Recommendation: Hybrid Approach

### Recommended: Solution 1 (AWS Budgets) + Solution 2 (Rate Limiting)

**Why:**
1. **AWS Budgets** provides immediate, account-level protection (hard stop)
2. **Rate Limiting** provides application-level prevention (soft limit)
3. Together they provide defense in depth

### Implementation Priority:
1. **Phase 1**: Implement AWS Budgets (Solution 1) - **Immediate protection**
2. **Phase 2**: Implement Rate Limiting (Solution 2) - **Preventive control**
3. **Phase 3** (Optional): Add Cost Anomaly Detection (Solution 3) - **Advanced monitoring**

### Estimated Costs:
- **Solution 1**: $0 (AWS Budgets is free)
- **Solution 2**: ~$0.10-0.50/month (DynamoDB on-demand, minimal usage)
- **Solution 3**: ~$0.50-1.00/month (Lambda execution costs)

**Total**: < $2/month for comprehensive cost protection

---

## Next Steps

1. Review and select solution(s)
2. Create Terraform configuration
3. Implement rate limiting code changes
4. Test in staging environment
5. Deploy to production
6. Monitor and adjust thresholds

