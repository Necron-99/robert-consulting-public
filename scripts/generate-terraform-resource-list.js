#!/usr/bin/env node

/**
 * Generate list of Terraform-managed resource ARNs
 * Reads Terraform state and outputs resource ARNs for the cataloger
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Script can be run from root or terraform directory
const ROOT_DIR = path.resolve(__dirname, '..');
const TERRAFORM_DIR = path.join(ROOT_DIR, 'terraform');
const OUTPUT_FILE = path.join(TERRAFORM_DIR, 'terraform-resource-arns.json');

// Resource type to ARN mapping
const RESOURCE_TYPE_MAP = {
  'aws_s3_bucket': (state) => {
    // Try multiple ways to get bucket name
    // Terraform state JSON structure: state.values or state.attributes
    const bucket = state.values?.bucket || 
                   state.attributes?.bucket || 
                   state.attributes?.id ||
                   state.values?.id ||
                   (state.values && Object.keys(state.values).length > 0 ? Object.values(state.values)[0] : null);
    
    // If still no bucket, try to extract from ARN if present
    if (!bucket && state.values?.arn) {
      const arnMatch = state.values.arn.match(/arn:aws:s3:::(.+)/);
      if (arnMatch) return state.values.arn;
    }
    
    return bucket ? `arn:aws:s3:::${bucket}` : null;
  },
  'aws_cloudfront_distribution': (state) => {
    const id = state.values?.id || state.attributes?.id;
    const accountId = state.values?.account_id || state.attributes?.account_id || '228480945348';
    return id ? `arn:aws:cloudfront::${accountId}:distribution/${id}` : null;
  },
  'aws_lambda_function': (state) => {
    return state.values?.arn || state.attributes?.arn || null;
  },
  'aws_api_gateway_rest_api': (state) => {
    const id = state.values?.id || state.attributes?.id;
    const region = state.values?.region || state.attributes?.region || 'us-east-1';
    const accountId = state.values?.account_id || state.attributes?.account_id || '228480945348';
    return id ? `arn:aws:apigateway:${region}::/restapis/${id}` : null;
  },
  'aws_route53_zone': (state) => {
    const zoneId = state.values?.zone_id || state.attributes?.zone_id || state.values?.id || state.attributes?.id;
    return zoneId ? `arn:aws:route53:::hostedzone/${zoneId}` : null;
  },
  'aws_wafv2_web_acl': (state) => {
    return state.values?.arn || state.attributes?.arn || null;
  }
};

function getTerraformState() {
  try {
    console.log('📋 Getting Terraform state list...');
    const cwd = TERRAFORM_DIR;
    console.log(`   Working directory: ${cwd}`);
    const startTime = Date.now();
    const output = execSync('terraform state list', { 
      cwd, 
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
      maxBuffer: 10 * 1024 * 1024 // 10MB buffer
    });
    const duration = Date.now() - startTime;
    console.log(`   ✅ terraform state list completed in ${duration}ms`);
    
    // Parse text output into array
    const resources = output.trim().split('\n').filter(line => line.trim().length > 0);
    console.log(`✅ Found ${resources.length} resources in Terraform state`);
    return resources;
  } catch (error) {
    console.error('❌ Error reading Terraform state:', error.message);
    return [];
  }
}

function getResourceARN(resourceType, resourceName) {
  try {
    const cwd = TERRAFORM_DIR;
    const resourceAddress = `${resourceType}.${resourceName}`;
    
    // Use text format directly (Terraform version doesn't support -json flag)
    const startTime = Date.now();
    const output = execSync(`terraform state show "${resourceAddress}"`, {
      cwd,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
      maxBuffer: 10 * 1024 * 1024 // 10MB buffer
    });
    const duration = Date.now() - startTime;
    
    if (duration > 3000) {
      console.log(`      ⏱️  ${resourceAddress} took ${duration}ms`);
    }
      
    // Parse text output for ARN
    // First try to find ARN directly in output
    const arnMatch = output.match(/arn:aws:[^\s"']+/);
    if (arnMatch) {
      return arnMatch[0].replace(/["']/g, '').trim(); // Remove any quotes
    }
    
    // Try to extract ID/bucket/name and construct ARN
    const idMatch = output.match(/id\s+=\s+([^\s"']+)/);
    const bucketMatch = output.match(/bucket\s+=\s+([^\s"']+)/);
    const nameMatch = output.match(/name\s+=\s+([^\s"']+)/);
    const arnLineMatch = output.match(/arn\s+=\s+([^\s"']+)/);
    
    // If ARN is directly in the output
    if (arnLineMatch) {
      return arnLineMatch[1].replace(/["']/g, '').trim();
    }
    
    // Construct ARN based on resource type
    if (bucketMatch && resourceType === 'aws_s3_bucket') {
      const bucket = bucketMatch[1].replace(/["']/g, '').trim();
      return `arn:aws:s3:::${bucket}`;
    }
    
    if (idMatch) {
      const id = idMatch[1].replace(/["']/g, '').trim();
      
      if (resourceType === 'aws_cloudfront_distribution') {
        return `arn:aws:cloudfront::228480945348:distribution/${id}`;
      }
      
      if (resourceType === 'aws_lambda_function') {
        // Try to get function name
        if (nameMatch) {
          const funcName = nameMatch[1].replace(/["']/g, '').trim();
          return `arn:aws:lambda:us-east-1:228480945348:function:${funcName}`;
        }
        // Fallback: use ID as function name
        return `arn:aws:lambda:us-east-1:228480945348:function:${id}`;
      }
      
      if (resourceType === 'aws_api_gateway_rest_api') {
        return `arn:aws:apigateway:us-east-1::/restapis/${id}`;
      }
      
      if (resourceType === 'aws_route53_zone') {
        return `arn:aws:route53:::hostedzone/${id}`;
      }
    }
    
    return null;
  } catch (error) {
    // Resource might not exist in state or show failed
    return null;
  }
}

function generateResourceList() {
  console.log('🔍 Reading Terraform state...');
  const stateList = getTerraformState();
  
  if (!Array.isArray(stateList)) {
    console.error('❌ Invalid Terraform state format');
    process.exit(1);
  }
  
  console.log(`📋 Found ${stateList.length} resources in Terraform state`);
  
  const resourceARNs = [];
  const errors = [];
  let processed = 0;
  let skipped = 0;
  
  console.log('🔄 Processing resources to extract ARNs...');
  
  for (let i = 0; i < stateList.length; i++) {
    const resource = stateList[i];
    
    // Log progress every 20 resources
    if (i > 0 && i % 20 === 0) {
      console.log(`   📊 Progress: ${i}/${stateList.length} (${processed} ARNs found, ${skipped} skipped)`);
    }
    
    if (!resource || typeof resource !== 'string') {
      skipped++;
      continue;
    }
    
    // Skip data sources and modules for now
    if (resource.startsWith('data.') || resource.includes('module.')) {
      skipped++;
      continue;
    }
    
    // Parse resource type and name
    const match = resource.match(/^aws_(\w+)\.(.+)$/);
    if (!match) {
      skipped++;
      continue;
    }
    
    const resourceType = `aws_${match[1]}`;
    const resourceName = match[2];
    
    // Only process resources we can map to ARNs
    if (!RESOURCE_TYPE_MAP[resourceType]) {
      skipped++;
      continue;
    }
    
    // Get ARN
    try {
      const arn = getResourceARN(resourceType, resourceName);
      
      if (arn) {
        resourceARNs.push({
          arn: arn,
          terraformResource: resource,
          type: resourceType,
          name: resourceName
        });
        processed++;
      } else {
        errors.push(resource);
        skipped++;
      }
    } catch (error) {
      console.error(`   ⚠️  Error processing ${resource}: ${error.message}`);
      errors.push(resource);
      skipped++;
    }
  }
  
  console.log(`✅ Processing complete: ${processed} ARNs found, ${skipped} skipped, ${errors.length} errors`);
  
  console.log(`✅ Generated ${resourceARNs.length} resource ARNs`);
  if (errors.length > 0) {
    console.log(`⚠️  ${errors.length} resources could not be resolved`);
  }
  
  // Write to file
  // Clean ARNs: remove any quotes or extra whitespace
  const cleanedARNs = resourceARNs.map(r => {
    const arn = r.arn || r;
    if (typeof arn === 'string') {
      return arn.replace(/^["']|["']$/g, '').trim();
    }
    return arn;
  });
  
  const output = {
    generatedAt: new Date().toISOString(),
    totalResources: cleanedARNs.length,
    resources: cleanedARNs,
    resourceDetails: resourceARNs
  };
  
  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(output, null, 2));
  console.log(`📝 Written to ${OUTPUT_FILE}`);
  
  return output;
}

// Main
if (import.meta.url === `file://${process.argv[1]}`) {
  generateResourceList();
}

export { generateResourceList };

