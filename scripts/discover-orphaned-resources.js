#!/usr/bin/env node

/**
 * Discover AWS resources NOT managed by Terraform
 * Compares discovered AWS resources against Terraform state to find orphaned resources
 */

import { ResourceGroupsTaggingAPIClient, GetResourcesCommand } from '@aws-sdk/client-resource-groups-tagging-api';
import { S3Client, ListBucketsCommand, GetBucketTaggingCommand } from '@aws-sdk/client-s3';
import { CloudFrontClient, ListDistributionsCommand } from '@aws-sdk/client-cloudfront';
import { LambdaClient, ListFunctionsCommand } from '@aws-sdk/client-lambda';
// Route53 uses a different package structure - we'll use AWS CLI for now or skip if not available
// import { Route53Client, ListHostedZonesCommand } from '@aws-sdk/client-route53';
import apiGatewayPkg from '@aws-sdk/client-api-gateway';
const { APIGatewayClient, GetRestApisCommand } = apiGatewayPkg;
// WAFv2 - skip for now due to CommonJS/ESM compatibility issues
// Will discover WAF via Tagging API instead
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const ROOT_DIR = path.resolve(__dirname, '..');
const TERRAFORM_DIR = path.join(ROOT_DIR, 'terraform');
const TERRAFORM_ARNS_FILE = path.join(TERRAFORM_DIR, 'terraform-resource-arns.json');
const OUTPUT_FILE = path.join(TERRAFORM_DIR, 'orphaned-resources.json');

// AWS clients
const region = process.env.AWS_REGION || 'us-east-1';
const taggingClient = new ResourceGroupsTaggingAPIClient({ region });
const s3Client = new S3Client({ region });
const cloudfrontClient = new CloudFrontClient({ region: 'us-east-1' }); // CloudFront is global
const lambdaClient = new LambdaClient({ region });
// // Route53 uses AWS CLI instead of SDK (package structure differs)
const apiGatewayClient = new APIGatewayClient({ region });
// WAF client - skip for now, will discover via Tagging API
const wafClient = null;

// Resource types to discover
const TARGET_RESOURCE_TYPES = [
  's3:bucket',
  'cloudfront:distribution',
  'lambda:function',
  'apigateway:restapi',
  'route53:hostedzone',
  'wafv2:webacl'
];

/**
 * Load Terraform-managed ARNs
 */
function loadTerraformARNs() {
  try {
    if (!fs.existsSync(TERRAFORM_ARNS_FILE)) {
      console.warn(`⚠️  Terraform ARN file not found: ${TERRAFORM_ARNS_FILE}`);
      console.warn('   Run scripts/generate-terraform-resource-list.js first');
      return new Set();
    }
    
    const data = JSON.parse(fs.readFileSync(TERRAFORM_ARNS_FILE, 'utf8'));
    const arns = (data.resources || []).map(arn => {
      if (typeof arn === 'string') {
        return arn.replace(/^["']|["']$/g, '').trim();
      }
      return arn;
    });
    
    console.log(`📋 Loaded ${arns.length} Terraform-managed resource ARNs`);
    return new Set(arns);
  } catch (error) {
    console.error(`❌ Error loading Terraform ARNs: ${error.message}`);
    return new Set();
  }
}

/**
 * Discover resources via Resource Groups Tagging API
 */
async function discoverTaggedResources() {
  const resources = [];
  
  console.log('🔍 Discovering tagged resources via Resource Groups Tagging API...');
  
  for (const resourceType of TARGET_RESOURCE_TYPES) {
    try {
      let paginationToken = null;
      let pageCount = 0;
      
      do {
        const response = await taggingClient.send(new GetResourcesCommand({
          ResourceTypeFilters: [resourceType],
          ResourcesPerPage: 100,
          PaginationToken: paginationToken
        }));
        
        for (const resource of response.ResourceTagMappingList || []) {
          resources.push({
            arn: resource.ResourceARN,
            type: resourceType.split(':')[0],
            tags: resource.Tags || [],
            discoveredVia: 'tagging-api'
          });
        }
        
        paginationToken = response.PaginationToken;
        pageCount++;
      } while (paginationToken && pageCount < 100); // Safety limit
      
      console.log(`   ✅ Found ${resources.filter(r => r.type === resourceType.split(':')[0]).length} ${resourceType} resources`);
    } catch (error) {
      console.error(`   ❌ Error discovering ${resourceType}: ${error.message}`);
    }
  }
  
  return resources;
}

/**
 * Discover untagged S3 buckets
 */
async function discoverS3Buckets() {
  const buckets = [];
  
  try {
    console.log('🔍 Discovering S3 buckets...');
    const response = await s3Client.send(new ListBucketsCommand({}));
    
    for (const bucket of response.Buckets || []) {
      const bucketArn = `arn:aws:s3:::${bucket.Name}`;
      
      // Try to get tags
      let tags = [];
      try {
        const tagResponse = await s3Client.send(new GetBucketTaggingCommand({
          Bucket: bucket.Name
        }));
        tags = tagResponse.TagSet || [];
      } catch (error) {
        // Bucket might not have tags or we don't have permission
      }
      
      buckets.push({
        arn: bucketArn,
        type: 's3',
        name: bucket.Name,
        created: bucket.CreationDate,
        tags: tags,
        discoveredVia: 's3-api'
      });
    }
    
    console.log(`   ✅ Found ${buckets.length} S3 buckets`);
  } catch (error) {
    console.error(`   ❌ Error discovering S3 buckets: ${error.message}`);
  }
  
  return buckets;
}

/**
 * Discover CloudFront distributions
 */
async function discoverCloudFrontDistributions() {
  const distributions = [];
  
  try {
    console.log('🔍 Discovering CloudFront distributions...');
    const response = await cloudfrontClient.send(new ListDistributionsCommand({}));
    
    for (const dist of response.DistributionList?.Items || []) {
      const distArn = `arn:aws:cloudfront::${dist.Id.split('/')[0] || '228480945348'}:distribution/${dist.Id}`;
      
      distributions.push({
        arn: distArn,
        type: 'cloudfront',
        id: dist.Id,
        domain: dist.DomainName,
        aliases: dist.Aliases?.Items || [],
        status: dist.Status,
        enabled: dist.Enabled,
        discoveredVia: 'cloudfront-api'
      });
    }
    
    console.log(`   ✅ Found ${distributions.length} CloudFront distributions`);
  } catch (error) {
    console.error(`   ❌ Error discovering CloudFront distributions: ${error.message}`);
  }
  
  return distributions;
}

/**
 * Discover Lambda functions
 */
async function discoverLambdaFunctions() {
  const functions = [];
  
  try {
    console.log('🔍 Discovering Lambda functions...');
    const response = await lambdaClient.send(new ListFunctionsCommand({}));
    
    for (const func of response.Functions || []) {
      functions.push({
        arn: func.FunctionArn,
        type: 'lambda',
        name: func.FunctionName,
        runtime: func.Runtime,
        lastModified: func.LastModified,
        discoveredVia: 'lambda-api'
      });
    }
    
    console.log(`   ✅ Found ${functions.length} Lambda functions`);
  } catch (error) {
    console.error(`   ❌ Error discovering Lambda functions: ${error.message}`);
  }
  
  return functions;
}

/**
 * Discover Route53 hosted zones
 * Note: Using AWS CLI since SDK package structure differs
 */
async function discoverRoute53Zones() {
  const zones = [];
  
  try {
    console.log('🔍 Discovering Route53 hosted zones...');
    // Use AWS CLI for Route53 since SDK package structure is different
    try {
      const output = execSync('aws route53 list-hosted-zones --output json', {
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe']
      });
      
      const response = JSON.parse(output);
      
      for (const zone of response.HostedZones || []) {
        const zoneId = zone.Id.split('/').pop();
        const zoneArn = `arn:aws:route53:::hostedzone/${zoneId}`;
        
        zones.push({
          arn: zoneArn,
          type: 'route53',
          id: zone.Id,
          name: zone.Name,
          recordCount: zone.ResourceRecordSetCount,
          discoveredVia: 'route53-cli'
        });
      }
      
      console.log(`   ✅ Found ${zones.length} Route53 hosted zones`);
    } catch (cliError) {
      console.log(`   ⚠️  Could not use AWS CLI for Route53: ${cliError.message}`);
      console.log(`   ⚠️  Route53 zones will be discovered via Tagging API only`);
    }
  } catch (error) {
    console.error(`   ❌ Error discovering Route53 zones: ${error.message}`);
  }
  
  return zones;
}

/**
 * Discover API Gateway REST APIs
 */
async function discoverAPIGatewayAPIs() {
  const apis = [];
  
  try {
    console.log('🔍 Discovering API Gateway REST APIs...');
    const response = await apiGatewayClient.send(new GetRestApisCommand({}));
    
    for (const api of response.items || []) {
      const apiArn = `arn:aws:apigateway:${region}::/restapis/${api.id}`;
      
      apis.push({
        arn: apiArn,
        type: 'apigateway',
        id: api.id,
        name: api.name,
        created: api.createdDate,
        discoveredVia: 'apigateway-api'
      });
    }
    
    console.log(`   ✅ Found ${apis.length} API Gateway REST APIs`);
  } catch (error) {
    console.error(`   ❌ Error discovering API Gateway APIs: ${error.message}`);
  }
  
  return apis;
}

/**
 * Discover WAFv2 Web ACLs
 */
async function discoverWAFWebACLs() {
  const webacls = [];
  
  if (!wafClient || !ListWebACLsCommand) {
    console.log('   ⚠️  WAFv2 SDK not available, skipping WAF discovery');
    return webacls;
  }
  
  try {
    console.log('🔍 Discovering WAFv2 Web ACLs...');
    
    // WAF can be regional or CloudFront (global)
    const scopes = ['REGIONAL', 'CLOUDFRONT'];
    
    for (const scope of scopes) {
      try {
        const response = await wafClient.send(new ListWebACLsCommand({
          Scope: scope
        }));
        
        for (const webacl of response.WebACLs || []) {
          const webaclArn = webacl.ARN || `arn:aws:wafv2:${scope === 'CLOUDFRONT' ? 'us-east-1' : region}:228480945348:global/webacl/${webacl.Name}/${webacl.Id}`;
          
          webacls.push({
            arn: webaclArn,
            type: 'wafv2',
            id: webacl.Id,
            name: webacl.Name,
            scope: scope,
            discoveredVia: 'waf-api'
          });
        }
      } catch (error) {
        // Some scopes might not be accessible
        console.log(`   ⚠️  Could not access WAF scope ${scope}: ${error.message}`);
      }
    }
    
    console.log(`   ✅ Found ${webacls.length} WAFv2 Web ACLs`);
  } catch (error) {
    console.error(`   ❌ Error discovering WAF Web ACLs: ${error.message}`);
  }
  
  return webacls;
}

/**
 * Main discovery function
 */
async function discoverAllResources() {
  console.log('🚀 Starting AWS resource discovery...');
  console.log('');
  
  // Load Terraform ARNs
  const terraformARNs = loadTerraformARNs();
  console.log('');
  
  // Discover all resources
  const [
    taggedResources,
    s3Buckets,
    cloudfrontDistributions,
    lambdaFunctions,
    route53Zones,
    apiGatewayAPIs,
    wafWebACLs
  ] = await Promise.all([
    discoverTaggedResources(),
    discoverS3Buckets(),
    discoverCloudFrontDistributions(),
    discoverLambdaFunctions(),
    discoverRoute53Zones(),
    discoverAPIGatewayAPIs(),
    discoverWAFWebACLs()
  ]);
  
  console.log('');
  console.log('📊 Consolidating discovered resources...');
  
  // Combine all resources and deduplicate by ARN
  const allResources = new Map();
  
  // Add tagged resources
  for (const resource of taggedResources) {
    allResources.set(resource.arn, resource);
  }
  
  // Add untagged resources (only if not already found)
  for (const resource of [
    ...s3Buckets,
    ...cloudfrontDistributions,
    ...lambdaFunctions,
    ...route53Zones,
    ...apiGatewayAPIs,
    ...wafWebACLs
  ]) {
    if (!allResources.has(resource.arn)) {
      allResources.set(resource.arn, resource);
    }
  }
  
  console.log(`✅ Discovered ${allResources.size} total AWS resources`);
  console.log('');
  
  // Identify orphaned resources (not in Terraform)
  const orphanedResources = [];
  const managedResources = [];
  
  for (const [arn, resource] of allResources.entries()) {
    if (terraformARNs.has(arn)) {
      managedResources.push(resource);
    } else {
      orphanedResources.push(resource);
    }
  }
  
  // Group orphaned resources by type
  const orphanedByType = {};
  for (const resource of orphanedResources) {
    if (!orphanedByType[resource.type]) {
      orphanedByType[resource.type] = [];
    }
    orphanedByType[resource.type].push(resource);
  }
  
  // Generate report
  const report = {
    generatedAt: new Date().toISOString(),
    summary: {
      totalDiscovered: allResources.size,
      terraformManaged: managedResources.length,
      orphaned: orphanedResources.length,
      orphanedByType: Object.keys(orphanedByType).reduce((acc, type) => {
        acc[type] = orphanedByType[type].length;
        return acc;
      }, {})
    },
    orphanedResources: orphanedResources,
    orphanedByType: orphanedByType,
    managedResources: managedResources.length // Just count, not full list
  };
  
  // Write output
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(report, null, 2));
  
  console.log('📊 Discovery Summary:');
  console.log(`   Total discovered: ${report.summary.totalDiscovered}`);
  console.log(`   Terraform-managed: ${report.summary.terraformManaged}`);
  console.log(`   Orphaned (not in Terraform): ${report.summary.orphaned}`);
  console.log('');
  console.log('📋 Orphaned resources by type:');
  for (const [type, count] of Object.entries(report.summary.orphanedByType)) {
    console.log(`   ${type}: ${count}`);
  }
  console.log('');
  console.log(`📝 Full report written to: ${OUTPUT_FILE}`);
  
  return report;
}

// Run discovery
discoverAllResources().catch(error => {
  console.error('❌ Fatal error:', error);
  process.exit(1);
});

