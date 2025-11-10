#!/usr/bin/env node

/**
 * Terraform Plan Analyzer
 * Analyzes terraform plan JSON output and determines if resources should be created or imported
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// AWS CLI commands to check if resources exist
const RESOURCE_CHECKERS = {
  'aws_s3_bucket': (id) => {
    try {
      execSync(`aws s3api head-bucket --bucket "${id}"`, { stdio: 'ignore' });
      return { exists: true, importId: id };
    } catch {
      return { exists: false };
    }
  },
  'aws_cloudfront_distribution': (id) => {
    try {
      execSync(`aws cloudfront get-distribution --id "${id}"`, { stdio: 'ignore' });
      return { exists: true, importId: id };
    } catch {
      return { exists: false };
    }
  },
  'aws_lambda_function': (id) => {
    try {
      execSync(`aws lambda get-function --function-name "${id}"`, { stdio: 'ignore' });
      return { exists: true, importId: id };
    } catch {
      return { exists: false };
    }
  },
  'aws_route53_record': (values) => {
    // Route53 records need zone_id + name + type
    const zoneId = values.zone_id || values.hosted_zone_id;
    const name = values.name;
    const type = values.type || 'A';
    if (zoneId && name) {
      try {
        // Try to find the record
        const output = execSync(
          `aws route53 list-resource-record-sets --hosted-zone-id "${zoneId}" --query "ResourceRecordSets[?Name=='${name}' && Type=='${type}']"`,
          { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }
        );
        const records = JSON.parse(output);
        if (records && records.length > 0) {
          return { exists: true, importId: `${zoneId}_${name}_${type}` };
        }
      } catch {
        // Continue to return unknown
      }
    }
    return { exists: null, importId: zoneId && name ? `${zoneId}_${name}_${values.type || 'A'}` : null };
  },
  'aws_route53_zone': (id) => {
    try {
      execSync(`aws route53 get-hosted-zone --id "${id}"`, { stdio: 'ignore' });
      return { exists: true, importId: id };
    } catch {
      return { exists: false };
    }
  },
  'aws_api_gateway_rest_api': (id) => {
    try {
      execSync(`aws apigateway get-rest-api --rest-api-id "${id}"`, { stdio: 'ignore' });
      return { exists: true, importId: id };
    } catch {
      return { exists: false };
    }
  },
  'aws_iam_role': (id) => {
    try {
      execSync(`aws iam get-role --role-name "${id}"`, { stdio: 'ignore' });
      return { exists: true, importId: id };
    } catch {
      return { exists: false };
    }
  },
  'aws_dynamodb_table': (id) => {
    try {
      execSync(`aws dynamodb describe-table --table-name "${id}"`, { stdio: 'ignore' });
      return { exists: true, importId: id };
    } catch {
      return { exists: false };
    }
  },
  'aws_sns_topic': (values) => {
    // SNS topics can be checked by name or ARN
    const name = values.name;
    if (name) {
      try {
        const output = execSync(
          `aws sns list-topics --query "Topics[?contains(TopicArn, '${name}')].TopicArn" --output text`,
          { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }
        );
        if (output.trim()) {
          return { exists: true, importId: output.trim().split('\t')[0] };
        }
      } catch {
        // Continue
      }
    }
    return { exists: null };
  }
};

function extractResourceId(resourceType, values) {
  // Try common ID fields
  return values.id || 
         values.bucket || 
         values.name || 
         values.function_name || 
         values.distribution_id ||
         values.zone_id ||
         values.hosted_zone_id ||
         values.table_name ||
         null;
}

function analyzePlan(planJsonPath) {
  console.log('🔍 Analyzing Terraform Plan...\n');
  
  const planData = JSON.parse(fs.readFileSync(planJsonPath, 'utf8'));
  
  const resourcesToImport = [];
  const resourcesToCreate = [];
  const resourcesToCheck = [];
  
  // Process resource_changes
  if (planData.resource_changes) {
    for (const change of planData.resource_changes) {
      const actions = change.change?.actions || [];
      
      // Only process resources being created
      if (!actions.includes('create')) {
        continue;
      }
      
      const address = change.address;
      const resourceType = change.type;
      const values = change.change?.after || {};
      const resourceId = extractResourceId(resourceType, values);
      
      console.log(`📋 ${address}`);
      console.log(`   Type: ${resourceType}`);
      if (resourceId) {
        console.log(`   ID: ${resourceId}`);
      }
      
      // Check if resource exists
      const checker = RESOURCE_CHECKERS[resourceType];
      if (checker) {
        const result = checker(resourceId || values);
        
        if (result.exists === true) {
          console.log(`   ${'\x1b[33m'}Status: EXISTS - Should be IMPORTED${'\x1b[0m'}`);
          console.log(`   ${'\x1b[32m'}→ Import: terraform import ${address} ${result.importId || resourceId}${'\x1b[0m'}`);
          resourcesToImport.push({
            address,
            type: resourceType,
            importId: result.importId || resourceId,
            command: `terraform import ${address} ${result.importId || resourceId}`
          });
        } else if (result.exists === false) {
          console.log(`   ${'\x1b[32m'}Status: NEW - Should be CREATED${'\x1b[0m'}`);
          resourcesToCreate.push({ address, type: resourceType });
        } else {
          console.log(`   ${'\x1b[36m'}Status: MANUAL CHECK REQUIRED${'\x1b[0m'}`);
          resourcesToCheck.push({ address, type: resourceType, reason: 'Cannot auto-detect' });
        }
      } else {
        console.log(`   ${'\x1b[36m'}Status: UNKNOWN TYPE - Manual review needed${'\x1b[0m'}`);
        resourcesToCheck.push({ address, type: resourceType, reason: 'No checker available' });
      }
      console.log('');
    }
  }
  
  // Generate import commands file
  if (resourcesToImport.length > 0) {
    const importFile = path.join(__dirname, '..', 'terraform-import-commands.sh');
    let content = '#!/bin/bash\n';
    content += '# Auto-generated import commands\n';
    content += '# Review before running!\n\n';
    content += 'set -e\n\n';
    
    for (const resource of resourcesToImport) {
      content += `# ${resource.type}\n`;
      content += `${resource.command}\n\n`;
    }
    
    fs.writeFileSync(importFile, content);
    fs.chmodSync(importFile, 0o755);
    console.log(`✅ Import commands saved to: terraform-import-commands.sh\n`);
  }
  
  // Summary
  console.log('==========================');
  console.log('📊 Summary:\n');
  console.log(`   ${'\x1b[33m'}Resources to IMPORT: ${resourcesToImport.length}${'\x1b[0m'}`);
  console.log(`   ${'\x1b[32m'}Resources to CREATE: ${resourcesToCreate.length}${'\x1b[0m'}`);
  console.log(`   ${'\x1b[36m'}Resources to CHECK: ${resourcesToCheck.length}${'\x1b[0m'}\n`);
  
  if (resourcesToCheck.length > 0) {
    console.log('⚠️  Resources requiring manual review:');
    for (const resource of resourcesToCheck) {
      console.log(`   - ${resource.address} (${resource.type}) - ${resource.reason}`);
    }
    console.log('');
  }
  
  return {
    toImport: resourcesToImport,
    toCreate: resourcesToCreate,
    toCheck: resourcesToCheck
  };
}

// Main
if (import.meta.url === `file://${process.argv[1]}`) {
  const planFile = process.argv[2] || 'terraform-plan.json';
  
  if (!fs.existsSync(planFile)) {
    console.error(`❌ Plan file not found: ${planFile}`);
    console.log('\n💡 Generate plan JSON with: terraform plan -out=tfplan && terraform show -json tfplan > terraform-plan.json');
    process.exit(1);
  }
  
  analyzePlan(planFile);
}

export { analyzePlan };

