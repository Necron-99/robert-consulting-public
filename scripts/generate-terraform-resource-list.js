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
    const cwd = TERRAFORM_DIR;
    const output = execSync('terraform state list', { 
      cwd, 
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    });
    // Parse text output into array
    return output.trim().split('\n').filter(line => line.trim().length > 0);
  } catch (error) {
    console.error('Error reading Terraform state:', error.message);
    return [];
  }
}

function getResourceARN(resourceType, resourceName) {
  try {
    const cwd = TERRAFORM_DIR;
    const resourceAddress = `${resourceType}.${resourceName}`;
    
    // Try JSON format first (Terraform 1.0+)
    let output;
    try {
      output = execSync(`terraform state show -json "${resourceAddress}"`, {
        cwd,
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe']
      });
    } catch (jsonError) {
      // Fallback to text format and parse
      output = execSync(`terraform state show "${resourceAddress}"`, {
        cwd,
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'pipe']
      });
      
      // Parse text output for ARN
      const arnMatch = output.match(/arn:aws:[^\s]+/);
      if (arnMatch) {
        return arnMatch[0];
      }
      
      // Try to extract ID and construct ARN
      const idMatch = output.match(/id\s+=\s+([^\s]+)/);
      const bucketMatch = output.match(/bucket\s+=\s+([^\s]+)/);
      const nameMatch = output.match(/name\s+=\s+([^\s]+)/);
      
      if (bucketMatch && resourceType === 'aws_s3_bucket') {
        return `arn:aws:s3:::${bucketMatch[1]}`;
      }
      
      if (idMatch) {
        const id = idMatch[1];
        if (resourceType === 'aws_cloudfront_distribution') {
          return `arn:aws:cloudfront::228480945348:distribution/${id}`;
        }
        if (resourceType === 'aws_lambda_function' && nameMatch) {
          // Lambda ARN format: arn:aws:lambda:region:account:function:name
          return `arn:aws:lambda:us-east-1:228480945348:function:${nameMatch[1]}`;
        }
      }
      
      return null;
    }
    
    // Parse JSON output
    const state = JSON.parse(output);
    
    // First try to get ARN directly (most reliable)
    if (state.values?.arn) {
      return state.values.arn;
    }
    if (state.attributes?.arn) {
      return state.attributes.arn;
    }
    
    // Then try resource-specific mapper
    const mapper = RESOURCE_TYPE_MAP[resourceType];
    if (mapper) {
      const arn = mapper(state);
      if (arn) return arn;
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
  
  for (const resource of stateList) {
    if (!resource || typeof resource !== 'string') {
      continue;
    }
    // Skip data sources and modules for now
    if (resource.startsWith('data.') || resource.includes('module.')) {
      continue;
    }
    
    // Parse resource type and name
    const match = resource.match(/^aws_(\w+)\.(.+)$/);
    if (!match) {
      continue;
    }
    
    const resourceType = `aws_${match[1]}`;
    const resourceName = match[2];
    
    // Get ARN
    const arn = getResourceARN(resourceType, resourceName);
    if (arn) {
      resourceARNs.push({
        arn: arn,
        terraformResource: resource,
        type: resourceType,
        name: resourceName
      });
    } else {
      errors.push(resource);
    }
  }
  
  console.log(`✅ Generated ${resourceARNs.length} resource ARNs`);
  if (errors.length > 0) {
    console.log(`⚠️  ${errors.length} resources could not be resolved`);
  }
  
  // Write to file
  const output = {
    generatedAt: new Date().toISOString(),
    totalResources: resourceARNs.length,
    resources: resourceARNs.map(r => r.arn),
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

