/**
 * API Rate Limiting and Cost Tracking Utility
 * Prevents excessive AWS API calls that could lead to high costs
 */

const { DynamoDBClient, PutItemCommand, GetItemCommand } = require('@aws-sdk/client-dynamodb');
const { SNSClient, PublishCommand } = require('@aws-sdk/client-sns');
const { CloudWatchClient, PutMetricDataCommand } = require('@aws-sdk/client-cloudwatch');

const dynamodb = new DynamoDBClient({ region: 'us-east-1' });
const sns = new SNSClient({ region: 'us-east-1' });
const cloudwatch = new CloudWatchClient({ region: 'us-east-1' });

const RATE_LIMIT_TABLE = process.env.RATE_LIMIT_TABLE || 'api-rate-limits';
const COST_TRACKER_TABLE = process.env.COST_TRACKER_TABLE || 'api-cost-tracking';
const COST_ALERT_TOPIC_ARN = process.env.COST_ALERT_TOPIC_ARN || '';

// Rate limiting configuration per API call type
const RATE_LIMITS = {
  'cloudwatch:GetMetricData': { maxCalls: 100, windowMs: 3600000 }, // 100/hour
  'cloudwatch:GetMetricStatistics': { maxCalls: 50, windowMs: 3600000 }, // 50/hour
  'route53:ListHostedZones': { maxCalls: 10, windowMs: 3600000 },   // 10/hour
  'route53:ListResourceRecordSets': { maxCalls: 20, windowMs: 3600000 }, // 20/hour
  's3:ListBuckets': { maxCalls: 20, windowMs: 3600000 },             // 20/hour
  's3:GetObject': { maxCalls: 1000, windowMs: 3600000 },              // 1000/hour (high, but S3 is cheap)
  's3:PutObject': { maxCalls: 100, windowMs: 3600000 },               // 100/hour
  'cloudfront:ListDistributions': { maxCalls: 10, windowMs: 3600000 }, // 10/hour
  'lambda:ListFunctions': { maxCalls: 10, windowMs: 3600000 },      // 10/hour
  'lambda:GetFunction': { maxCalls: 50, windowMs: 3600000 },          // 50/hour
  'wafv2:ListWebACLs': { maxCalls: 10, windowMs: 3600000 },            // 10/hour
  'apigateway:GetRestApis': { maxCalls: 10, windowMs: 3600000 },       // 10/hour
  'iam:ListRoles': { maxCalls: 5, windowMs: 3600000 },                // 5/hour (expensive)
  'iam:ListPolicies': { maxCalls: 5, windowMs: 3600000 },             // 5/hour (expensive)
  'dynamodb:ListTables': { maxCalls: 10, windowMs: 3600000 },          // 10/hour
  'cost-explorer:GetCostAndUsage': { maxCalls: 0, windowMs: 3600000 }  // BLOCKED
};

// Estimated cost per API call (in USD)
const API_COSTS = {
  'cloudwatch:GetMetricData': 0.00001,  // $0.01 per 1,000 calls
  'cloudwatch:GetMetricStatistics': 0.00001,
  'route53:ListHostedZones': 0.0005,     // $0.50 per 1,000 calls
  'route53:ListResourceRecordSets': 0.0005,
  's3:ListBuckets': 0.0005,              // $0.50 per 1,000 calls
  's3:GetObject': 0.0000004,             // Very cheap
  's3:PutObject': 0.000005,              // $0.005 per 1,000 calls
  'cloudfront:ListDistributions': 0.0,  // Free
  'lambda:ListFunctions': 0.0,          // Free
  'lambda:GetFunction': 0.0,             // Free
  'wafv2:ListWebACLs': 0.0,              // Free
  'apigateway:GetRestApis': 0.0,         // Free
  'iam:ListRoles': 0.0,                  // Free
  'iam:ListPolicies': 0.0,               // Free
  'dynamodb:ListTables': 0.0,            // Free
  'cost-explorer:GetCostAndUsage': 0.0   // Free (but blocked to prevent accidental usage)
};

// Daily cost threshold for alerts
const DAILY_COST_THRESHOLD = 5.0; // $5/day

/**
 * Check if an API call is within rate limits
 * @param {string} apiCall - The API call identifier (e.g., 'cloudwatch:GetMetricData')
 * @returns {Promise<{allowed: boolean, reason?: string, remaining?: number, warning?: string}>}
 */
async function checkRateLimit(apiCall) {
  const limit = RATE_LIMITS[apiCall];
  
  // If no limit configured, allow the call (but log a warning)
  if (!limit) {
    console.warn(`No rate limit configured for ${apiCall}, allowing by default`);
    return { allowed: true, warning: 'No rate limit configured' };
  }
  
  // If explicitly blocked (maxCalls === 0), deny immediately
  if (limit.maxCalls === 0) {
    console.warn(`API call ${apiCall} is blocked by policy`);
    return { allowed: false, reason: 'API call blocked by policy' };
  }

  const now = Date.now();
  const windowStart = Math.floor(now / limit.windowMs) * limit.windowMs;
  const key = `${apiCall}:${windowStart}`;

  try {
    const result = await dynamodb.send(new GetItemCommand({
      TableName: RATE_LIMIT_TABLE,
      Key: { apiCall: { S: key } }
    }));

    const currentCount = result.Item ? parseInt(result.Item.count.N, 10) : 0;
    
    if (currentCount >= limit.maxCalls) {
      console.warn(`Rate limit exceeded for ${apiCall}: ${currentCount}/${limit.maxCalls} calls in window`);
      return { 
        allowed: false, 
        reason: `Rate limit exceeded: ${currentCount}/${limit.maxCalls} calls in window`,
        remaining: 0
      };
    }

    // Increment counter
    const newCount = currentCount + 1;
    const ttl = Math.floor(now / 1000) + Math.floor(limit.windowMs / 1000);
    
    await dynamodb.send(new PutItemCommand({
      TableName: RATE_LIMIT_TABLE,
      Item: {
        apiCall: { S: key },
        count: { N: String(newCount) },
        ttl: { N: String(ttl) }
      }
    }));

    // Track cost
    await trackAPICost(apiCall);

    return { 
      allowed: true, 
      remaining: limit.maxCalls - newCount 
    };
  } catch (error) {
    console.error('Rate limit check failed:', error);
    // Fail open for availability, but log the error
    return { allowed: true, warning: 'Rate limit check failed, allowing call' };
  }
}

/**
 * Track API call costs
 * @param {string} apiCall - The API call identifier
 */
async function trackAPICost(apiCall) {
  const cost = API_COSTS[apiCall] || 0;
  if (cost === 0) return; // Skip tracking for free APIs

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
    if (newCost > DAILY_COST_THRESHOLD && currentCost <= DAILY_COST_THRESHOLD) {
      await sendCostAlert(newCost, today, apiCall);
    }

    // Store updated cost
    const ttl = Math.floor(Date.now() / 1000) + (86400 * 7); // 7 days retention
    
    await dynamodb.send(new PutItemCommand({
      TableName: COST_TRACKER_TABLE,
      Item: {
        date: { S: key },
        cost: { N: String(newCost) },
        lastUpdated: { S: new Date().toISOString() },
        lastApiCall: { S: apiCall },
        ttl: { N: String(ttl) }
      }
    }));

    // Publish custom metric to CloudWatch
    await publishCostMetric(newCost, date);

    console.log(`Tracked API cost: ${apiCall} = $${cost.toFixed(6)}, Daily total: $${newCost.toFixed(2)}`);
  } catch (error) {
    console.error('Cost tracking failed:', error);
    // Don't throw - cost tracking failure shouldn't break the application
  }
}

/**
 * Send cost alert via SNS
 * @param {number} cost - Current daily cost
 * @param {string} date - Date string
 * @param {string} apiCall - API call that triggered the alert
 */
async function sendCostAlert(cost, date, apiCall) {
  if (!COST_ALERT_TOPIC_ARN) {
    console.warn('Cost alert topic ARN not configured, skipping alert');
    return;
  }

  try {
    await sns.send(new PublishCommand({
      TopicArn: COST_ALERT_TOPIC_ARN,
      Subject: `⚠️ High API Cost Alert: $${cost.toFixed(2)} on ${date}`,
      Message: `API costs have exceeded $${DAILY_COST_THRESHOLD.toFixed(2)} threshold.\n\n` +
               `Current daily cost: $${cost.toFixed(2)}\n` +
               `Last API call: ${apiCall}\n` +
               `Date: ${date}\n\n` +
               `Please review API usage and rate limits.`
    }));
    console.log(`Cost alert sent: $${cost.toFixed(2)} on ${date}`);
  } catch (error) {
    console.error('Failed to send cost alert:', error);
  }
}

/**
 * Publish cost metric to CloudWatch
 * @param {number} cost - Current daily cost
 * @param {string} date - Date string
 */
async function publishCostMetric(cost, date) {
  try {
    await cloudwatch.send(new PutMetricDataCommand({
      Namespace: 'CostControl/API',
      MetricData: [{
        MetricName: 'DailyAPICost',
        Value: cost,
        Unit: 'None',
        Timestamp: new Date(),
        Dimensions: [{
          Name: 'Date',
          Value: date
        }]
      }]
    }));
  } catch (error) {
    console.error('Failed to publish cost metric to CloudWatch:', error);
    // Don't throw - metric publishing failure shouldn't break the application
  }
}

/**
 * Get current daily cost
 * @returns {Promise<number>} Current daily cost in USD
 */
async function getDailyCost() {
  const today = new Date().toISOString().split('T')[0];
  const key = `cost:${today}`;

  try {
    const result = await dynamodb.send(new GetItemCommand({
      TableName: COST_TRACKER_TABLE,
      Key: { date: { S: key } }
    }));

    return result.Item ? parseFloat(result.Item.cost.N) : 0;
  } catch (error) {
    console.error('Failed to get daily cost:', error);
    return 0;
  }
}

module.exports = {
  checkRateLimit,
  trackAPICost,
  getDailyCost,
  RATE_LIMITS,
  API_COSTS
};

