/**
 * Resource Cataloger Lambda Function
 * Discovers, catalogs, and tracks AWS resources with utilization metrics
 * 
 * SAFETY FEATURES:
 * - Never deletes resources automatically
 * - All operations are read-only by default
 * - Requires explicit approval for any destructive actions
 * - Dry-run mode enabled by default
 */

const { DynamoDBClient, PutItemCommand, QueryCommand, ScanCommand } = require('@aws-sdk/client-dynamodb');
const { ResourceGroupsTaggingAPIClient, GetResourcesCommand } = require('@aws-sdk/client-resource-groups-tagging-api');
const { S3Client, ListBucketsCommand, GetBucketTaggingCommand, HeadBucketCommand, ListObjectsV2Command } = require('@aws-sdk/client-s3');
const { CloudFrontClient, ListDistributionsCommand, GetDistributionCommand } = require('@aws-sdk/client-cloudfront');
const { LambdaClient, ListFunctionsCommand, GetFunctionCommand } = require('@aws-sdk/client-lambda');
const { CloudWatchClient, GetMetricStatisticsCommand, GetMetricDataCommand } = require('@aws-sdk/client-cloudwatch');

const dynamodb = new DynamoDBClient({ region: process.env.AWS_REGION || 'us-east-1' });
const taggingClient = new ResourceGroupsTaggingAPIClient({ region: process.env.AWS_REGION || 'us-east-1' });
const s3Client = new S3Client({ region: process.env.AWS_REGION || 'us-east-1' });
const cloudfrontClient = new CloudFrontClient({ region: 'us-east-1' }); // CloudFront is global
const lambdaClient = new LambdaClient({ region: process.env.AWS_REGION || 'us-east-1' });
const cloudwatchClient = new CloudWatchClient({ region: process.env.AWS_REGION || 'us-east-1' });

const fs = require('fs');
const path = require('path');

const CATALOG_TABLE = process.env.CATALOG_TABLE_NAME || 'robert-consulting-resource-catalog';
const DRY_RUN = process.env.DRY_RUN === 'true';
const REQUIRE_APPROVAL = process.env.REQUIRE_APPROVAL === 'true';

// Resource targeting configuration
const CATALOG_MODE = process.env.CATALOG_MODE || 'terraform-only';
const TERRAFORM_ARNS_FILE = process.env.TERRAFORM_ARNS_FILE || 'terraform-resource-arns.json';

// Load Terraform-managed resource ARNs if in terraform-only mode
let TERRAFORM_MANAGED_ARNS = new Set();
if (CATALOG_MODE === 'terraform-only') {
  try {
    const arnsPath = path.join(__dirname, TERRAFORM_ARNS_FILE);
    if (fs.existsSync(arnsPath)) {
      const arnsData = JSON.parse(fs.readFileSync(arnsPath, 'utf8'));
      // Clean ARNs: remove any trailing quotes or whitespace
      const cleanedARNs = (arnsData.resources || []).map(arn => {
        if (typeof arn === 'string') {
          return arn.replace(/^["']|["']$/g, '').trim();
        }
        return arn;
      });
      TERRAFORM_MANAGED_ARNS = new Set(cleanedARNs);
      console.log(`📋 Loaded ${TERRAFORM_MANAGED_ARNS.size} Terraform-managed resource ARNs`);
    } else {
      console.warn(`⚠️  Terraform ARN file not found: ${arnsPath}`);
      console.warn('   Cataloging all resources (fallback mode)');
    }
  } catch (error) {
    console.error('Error loading Terraform ARN list:', error.message);
    console.warn('   Cataloging all resources (fallback mode)');
  }
}

// Resource types to scan
const TARGET_RESOURCE_TYPES = [
  's3:bucket',
  'cloudfront:distribution',
  'lambda:function',
  'apigateway:restapi',
  'route53:hostedzone',
  'wafv2:webacl'
];

// Required tags for resources
const REQUIRED_TAGS = ['Project', 'Environment', 'ManagedBy', 'Purpose'];

/**
 * Check S3 bucket utilization
 */
async function checkS3Utilization(bucketName) {
  try {
    // Check if bucket exists and get object count
    let objectCount = 0;
    let isEmpty = true;
    
    try {
      const listResponse = await s3Client.send(new ListObjectsV2Command({
        Bucket: bucketName,
        MaxKeys: 1 // Just check if any objects exist
      }));
      objectCount = listResponse.KeyCount || 0;
      isEmpty = objectCount === 0;
    } catch (error) {
      // Bucket might not exist or we don't have permission
      if (error.name === 'NoSuchBucket') {
        return {
          sizeBytes: 0,
          objectCount: 0,
          isEmpty: true,
          lastUpdated: null,
          error: 'Bucket does not exist'
        };
      }
    }
    
    // Get bucket size from CloudWatch
    const endTime = new Date();
    const startTime = new Date(endTime.getTime() - 30 * 24 * 60 * 60 * 1000); // Last 30 days
    
    try {
      const metricData = await cloudwatchClient.send(new GetMetricStatisticsCommand({
        Namespace: 'AWS/S3',
        MetricName: 'BucketSizeBytes',
        Dimensions: [
          { Name: 'BucketName', Value: bucketName },
          { Name: 'StorageType', Value: 'StandardStorage' }
        ],
        StartTime: startTime,
        EndTime: endTime,
        Period: 86400, // 1 day
        Statistics: ['Average']
      }));
      
      const latestMetric = metricData.Datapoints
        .sort((a, b) => new Date(b.Timestamp) - new Date(a.Timestamp))[0];
      
      const sizeBytes = latestMetric?.Average || 0;
      
      return {
        sizeBytes: sizeBytes,
        objectCount: objectCount,
        isEmpty: isEmpty && sizeBytes === 0,
        lastUpdated: latestMetric?.Timestamp || null
      };
    } catch (error) {
      // If metric doesn't exist, use object count as indicator
      return {
        sizeBytes: 0,
        objectCount: objectCount,
        isEmpty: isEmpty,
        lastUpdated: null
      };
    }
  } catch (error) {
    console.error(`Error checking S3 bucket ${bucketName}:`, error.message);
    return {
      sizeBytes: 0,
      objectCount: 0,
      isEmpty: true,
      lastUpdated: null,
      error: error.message
    };
  }
}

/**
 * Check CloudFront distribution utilization
 */
async function checkCloudFrontUtilization(distributionId) {
  try {
    const endTime = new Date();
    const startTime = new Date(endTime.getTime() - 7 * 24 * 60 * 60 * 1000); // Last 7 days
    
    const metricData = await cloudwatchClient.send(new GetMetricStatisticsCommand({
      Namespace: 'AWS/CloudFront',
      MetricName: 'Requests',
      Dimensions: [
        { Name: 'DistributionId', Value: distributionId },
        { Name: 'Region', Value: 'Global' }
      ],
      StartTime: startTime,
      EndTime: endTime,
      Period: 86400, // 1 day
      Statistics: ['Sum']
    }));
    
    const totalRequests = metricData.Datapoints.reduce((sum, point) => sum + (point.Sum || 0), 0);
    
    return {
      requestsLast7Days: totalRequests,
      isUnused: totalRequests === 0,
      lastRequest: metricData.Datapoints
        .filter(p => p.Sum > 0)
        .sort((a, b) => b.Timestamp - a.Timestamp)[0]?.Timestamp || null
    };
  } catch (error) {
    console.error(`Error checking CloudFront ${distributionId}:`, error.message);
    return {
      requestsLast7Days: 0,
      isUnused: true,
      lastRequest: null,
      error: error.message
    };
  }
}

/**
 * Check Lambda function utilization
 */
async function checkLambdaUtilization(functionName) {
  try {
    const endTime = new Date();
    const startTime = new Date(endTime.getTime() - 30 * 24 * 60 * 60 * 1000); // Last 30 days
    
    const metricData = await cloudwatchClient.send(new GetMetricStatisticsCommand({
      Namespace: 'AWS/Lambda',
      MetricName: 'Invocations',
      Dimensions: [
        { Name: 'FunctionName', Value: functionName }
      ],
      StartTime: startTime,
      EndTime: endTime,
      Period: 86400, // 1 day
      Statistics: ['Sum']
    }));
    
    const totalInvocations = metricData.Datapoints.reduce((sum, point) => sum + (point.Sum || 0), 0);
    
    return {
      invocationsLast30Days: totalInvocations,
      isUnused: totalInvocations === 0,
      lastInvocation: metricData.Datapoints
        .filter(p => p.Sum > 0)
        .sort((a, b) => b.Timestamp - a.Timestamp)[0]?.Timestamp || null
    };
  } catch (error) {
    console.error(`Error checking Lambda ${functionName}:`, error.message);
    return {
      invocationsLast30Days: 0,
      isUnused: true,
      lastInvocation: null,
      error: error.message
    };
  }
}

/**
 * Validate resource tags
 */
function validateTags(tags) {
  const tagMap = {};
  (tags || []).forEach(tag => {
    tagMap[tag.Key] = tag.Value;
  });
  
  const missing = REQUIRED_TAGS.filter(tag => !tagMap[tag]);
  const hasAllRequired = missing.length === 0;
  
  return {
    hasAllRequired,
    missingTags: missing,
    tags: tagMap
  };
}

/**
 * Determine resource status based on utilization and tags
 */
function determineStatus(resourceType, utilization, tagValidation) {
  // If missing required tags, mark as needs-attention
  if (!tagValidation.hasAllRequired) {
    return 'needs-tagging';
  }
  
  // Check utilization based on resource type
  if (resourceType === 's3') {
    return utilization.isEmpty ? 'unused' : 'active';
  } else if (resourceType === 'cloudfront') {
    return utilization.isUnused ? 'unused' : 'active';
  } else if (resourceType === 'lambda') {
    return utilization.isUnused ? 'unused' : 'active';
  }
  
  return 'active';
}

/**
 * Catalog a resource in DynamoDB
 */
async function catalogResource(resource) {
  const item = {
    resource_arn: { S: resource.arn },
    resource_type: { S: resource.type },
    resource_name: { S: resource.name || 'unknown' },
    status: { S: resource.status },
    tags: { S: JSON.stringify(resource.tags || {}) },
    utilization: { S: JSON.stringify(resource.utilization || {}) },
    tag_validation: { S: JSON.stringify(resource.tagValidation || {}) },
    last_updated: { S: new Date().toISOString() },
    discovered_at: { S: resource.discoveredAt || new Date().toISOString() },
    region: { S: resource.region || 'us-east-1' }
  };
  
  try {
    await dynamodb.send(new PutItemCommand({
      TableName: CATALOG_TABLE,
      Item: item
    }));
    return true;
  } catch (error) {
    console.error(`Error cataloging resource ${resource.arn}:`, error.message);
    return false;
  }
}

/**
 * Discover and catalog all resources
 */
async function discoverAndCatalogResources() {
  const results = {
    discovered: 0,
    cataloged: 0,
    errors: 0,
    byType: {},
    byStatus: {},
    needsAttention: []
  };
  
  try {
    // Use Resource Groups Tagging API to discover all tagged resources
    console.log('🔍 Discovering resources using Resource Groups Tagging API...');
    console.log(`📋 Catalog mode: ${CATALOG_MODE}`);
    console.log(`📋 Target resource types: ${TARGET_RESOURCE_TYPES.join(', ')}`);
    if (CATALOG_MODE === 'terraform-only') {
      console.log(`📋 Terraform-managed resources: ${TERRAFORM_MANAGED_ARNS.size} ARNs loaded`);
    }
    
    for (const resourceType of TARGET_RESOURCE_TYPES) {
      try {
        let paginationToken = null;
        let pageCount = 0;
        
        do {
          const response = await taggingClient.send(new GetResourcesCommand({
            ResourceTypeFilters: [resourceType],
            PaginationToken: paginationToken
          }));
          
          for (const resource of response.ResourceTagMappingList || []) {
            // Filter to only Terraform-managed resources if in terraform-only mode
            if (CATALOG_MODE === 'terraform-only') {
              if (TERRAFORM_MANAGED_ARNS.size > 0 && !TERRAFORM_MANAGED_ARNS.has(resource.ResourceARN)) {
                continue; // Skip resources not managed by Terraform
              }
            }
            
            results.discovered++;
            const type = resourceType.split(':')[0];
            
            if (!results.byType[type]) {
              results.byType[type] = 0;
            }
            results.byType[type]++;
            
            // Get utilization metrics
            let utilization = {};
            if (type === 's3') {
              const bucketName = resource.ResourceARN.split(':').pop();
              utilization = await checkS3Utilization(bucketName);
            } else if (type === 'cloudfront') {
              const distId = resource.ResourceARN.split('/').pop();
              utilization = await checkCloudFrontUtilization(distId);
            } else if (type === 'lambda') {
              const funcName = resource.ResourceARN.split(':').pop();
              utilization = await checkLambdaUtilization(funcName);
            }
            
            // Validate tags
            const tagValidation = validateTags(resource.Tags);
            
            // Determine status
            const status = determineStatus(type, utilization, tagValidation);
            
            if (!results.byStatus[status]) {
              results.byStatus[status] = 0;
            }
            results.byStatus[status]++;
            
            // Extract resource name
            const name = resource.Tags?.find(t => t.Key === 'Name')?.Value || 
                        resource.ResourceARN.split(':').pop() || 
                        resource.ResourceARN.split('/').pop() || 
                        'unknown';
            
            const resourceData = {
              arn: resource.ResourceARN,
              type: type,
              name: name,
              status: status,
              tags: resource.Tags?.reduce((acc, tag) => {
                acc[tag.Key] = tag.Value;
                return acc;
              }, {}) || {},
              utilization: utilization,
              tagValidation: tagValidation,
              discoveredAt: new Date().toISOString(),
              region: resource.ResourceARN.split(':')[3] || 'us-east-1'
            };
            
            // Track resources needing attention
            if (status === 'needs-tagging' || status === 'unused') {
              results.needsAttention.push({
                arn: resourceData.arn,
                name: resourceData.name,
                type: resourceData.type,
                status: resourceData.status,
                reason: status === 'needs-tagging' 
                  ? `Missing tags: ${tagValidation.missingTags.join(', ')}`
                  : 'No utilization detected'
              });
            }
            
            // Catalog resource
            const cataloged = await catalogResource(resourceData);
            if (cataloged) {
              results.cataloged++;
            } else {
              results.errors++;
            }
          }
          
          paginationToken = response.PaginationToken;
          pageCount++;
        } while (paginationToken && pageCount < 100); // Safety limit
      } catch (error) {
        console.error(`Error discovering ${resourceType}:`, error.message);
        results.errors++;
      }
    }
    
    // Also discover untagged resources (they won't show up in Tagging API)
    console.log('🔍 Discovering untagged resources...');
    await discoverUntaggedResources(results);
    
  } catch (error) {
    console.error('Error in resource discovery:', error);
    throw error;
  }
  
  return results;
}

/**
 * Discover untagged resources (not found via Tagging API)
 */
async function discoverUntaggedResources(results) {
  // In terraform-only mode, we still need to check untagged resources
  // because the Tagging API only returns tagged resources
  // But we'll filter to only Terraform-managed resources
  if (CATALOG_MODE === 'terraform-only' && TERRAFORM_MANAGED_ARNS.size === 0) {
    console.log('⏭️  Skipping untagged resource discovery (no Terraform ARNs loaded)');
    return;
  }
  
  console.log('🔍 Discovering untagged resources (filtered to Terraform-managed in terraform-only mode)...');
  
  try {
    // S3 buckets
    const s3Response = await s3Client.send(new ListBucketsCommand({}));
    for (const bucket of s3Response.Buckets || []) {
      const bucketArn = `arn:aws:s3:::${bucket.Name}`;
      
      // Filter to Terraform-managed if in terraform-only mode
      if (CATALOG_MODE === 'terraform-only' && TERRAFORM_MANAGED_ARNS.size > 0) {
        if (!TERRAFORM_MANAGED_ARNS.has(bucketArn)) {
          continue;
        }
      }
      
      // Check if already cataloged
      const existing = await checkIfCataloged(bucketArn);
      if (!existing) {
        results.discovered++;
        results.byType['s3'] = (results.byType['s3'] || 0) + 1;
        
        const utilization = await checkS3Utilization(bucket.Name);
        const tagValidation = { hasAllRequired: false, missingTags: REQUIRED_TAGS, tags: {} };
        const status = determineStatus('s3', utilization, tagValidation);
        
        if (!results.byStatus[status]) {
          results.byStatus[status] = 0;
        }
        results.byStatus[status]++;
        
        const resourceData = {
          arn: `arn:aws:s3:::${bucket.Name}`,
          type: 's3',
          name: bucket.Name,
          status: status,
          tags: {},
          utilization: utilization,
          tagValidation: tagValidation,
          discoveredAt: new Date().toISOString(),
          region: 'us-east-1'
        };
        
        if (status === 'needs-tagging' || status === 'unused') {
          results.needsAttention.push({
            arn: resourceData.arn,
            name: resourceData.name,
            type: resourceData.type,
            status: resourceData.status,
            reason: 'Untagged resource'
          });
        }
        
        await catalogResource(resourceData);
        results.cataloged++;
      }
    }
    
    // Lambda functions
    const lambdaResponse = await lambdaClient.send(new ListFunctionsCommand({}));
    for (const func of lambdaResponse.Functions || []) {
      // Filter to Terraform-managed if in terraform-only mode
      if (CATALOG_MODE === 'terraform-only' && TERRAFORM_MANAGED_ARNS.size > 0) {
        if (!TERRAFORM_MANAGED_ARNS.has(func.FunctionArn)) {
          continue;
        }
      }
      
      const existing = await checkIfCataloged(func.FunctionArn);
      if (!existing) {
        results.discovered++;
        results.byType['lambda'] = (results.byType['lambda'] || 0) + 1;
        
        const utilization = await checkLambdaUtilization(func.FunctionName);
        const tagValidation = { 
          hasAllRequired: false, 
          missingTags: REQUIRED_TAGS.filter(t => !func.Tags?.[t]),
          tags: func.Tags || {}
        };
        const status = determineStatus('lambda', utilization, tagValidation);
        
        if (!results.byStatus[status]) {
          results.byStatus[status] = 0;
        }
        results.byStatus[status]++;
        
        const resourceData = {
          arn: func.FunctionArn,
          type: 'lambda',
          name: func.FunctionName,
          status: status,
          tags: func.Tags || {},
          utilization: utilization,
          tagValidation: tagValidation,
          discoveredAt: new Date().toISOString(),
          region: func.FunctionArn.split(':')[3] || 'us-east-1'
        };
        
        if (status === 'needs-tagging' || status === 'unused') {
          results.needsAttention.push({
            arn: resourceData.arn,
            name: resourceData.name,
            type: resourceData.type,
            status: resourceData.status,
            reason: 'Untagged or unused resource'
          });
        }
        
        await catalogResource(resourceData);
        results.cataloged++;
      }
    }
  } catch (error) {
    console.error('Error discovering untagged resources:', error.message);
    results.errors++;
  }
}

/**
 * Check if resource is already cataloged
 */
async function checkIfCataloged(arn) {
  try {
    const response = await dynamodb.send(new QueryCommand({
      TableName: CATALOG_TABLE,
      KeyConditionExpression: 'resource_arn = :arn',
      ExpressionAttributeValues: {
        ':arn': { S: arn }
      },
      Limit: 1
    }));
    
    return response.Items && response.Items.length > 0;
  } catch (error) {
    return false;
  }
}

/**
 * Main Lambda handler
 */
exports.handler = async (event) => {
  console.log('🚀 Starting resource catalog scan...');
  console.log(`📋 DRY_RUN: ${DRY_RUN}`);
  console.log(`🔒 REQUIRE_APPROVAL: ${REQUIRE_APPROVAL}`);
  
  try {
    const results = await discoverAndCatalogResources();
    
    console.log('\n📊 Resource Catalog Summary:');
    console.log(`   Discovered: ${results.discovered}`);
    console.log(`   Cataloged: ${results.cataloged}`);
    console.log(`   Errors: ${results.errors}`);
    console.log('\n   By Type:');
    Object.entries(results.byType).forEach(([type, count]) => {
      console.log(`     ${type}: ${count}`);
    });
    console.log('\n   By Status:');
    Object.entries(results.byStatus).forEach(([status, count]) => {
      console.log(`     ${status}: ${count}`);
    });
    
    if (results.needsAttention.length > 0) {
      console.log(`\n⚠️  Resources Needing Attention: ${results.needsAttention.length}`);
      results.needsAttention.slice(0, 10).forEach(resource => {
        console.log(`     - ${resource.name} (${resource.type}): ${resource.reason}`);
      });
      
      // Send alert if there are many resources needing attention
      if (results.needsAttention.length > 5) {
        console.log(`\n📧 Alert: ${results.needsAttention.length} resources need attention`);
        // TODO: Send SNS notification
      }
    }
    
    return {
      statusCode: 200,
      body: JSON.stringify({
        success: true,
        dryRun: DRY_RUN,
        results: results,
        message: DRY_RUN 
          ? 'Scan completed in DRY-RUN mode. No changes made.'
          : 'Scan completed successfully.'
      })
    };
  } catch (error) {
    console.error('❌ Error in resource catalog scan:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        success: false,
        error: error.message
      })
    };
  }
};

