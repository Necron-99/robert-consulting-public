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
    let name = values.name;
    const type = values.type || 'A';
    
    // Normalize name (add trailing dot if missing)
    if (name && !name.endsWith('.')) {
      name = name + '.';
    }
    
    if (zoneId && name) {
      try {
        // Try to find the record
        const output = execSync(
          `aws route53 list-resource-record-sets --hosted-zone-id "${zoneId}" --query "ResourceRecordSets[?Name=='${name}' && Type=='${type}']"`,
          { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }
        );
        const records = JSON.parse(output);
        if (records && records.length > 0) {
          // Import format: zone_id_name_type
          const importName = name.replace(/\.$/, ''); // Remove trailing dot for import
          return { exists: true, importId: `${zoneId}_${importName}_${type}` };
        }
      } catch (error) {
        // If zone doesn't exist or other error, try to construct import ID anyway
        if (zoneId && name) {
          const importName = name.replace(/\.$/, '');
          return { exists: null, importId: `${zoneId}_${importName}_${type}` };
        }
      }
    }
    return { exists: null, importId: null };
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
          const arn = output.trim().split('\t')[0];
          return { exists: true, importId: arn };
        }
      } catch {
        // Continue
      }
    }
    return { exists: null };
  },
  'aws_cloudwatch_dashboard': (values) => {
    const name = values.dashboard_name || values.name;
    if (name) {
      try {
        execSync(`aws cloudwatch get-dashboard --dashboard-name "${name}"`, { stdio: 'ignore' });
        return { exists: true, importId: name };
      } catch {
        return { exists: false };
      }
    }
    return { exists: null };
  },
  'aws_cloudwatch_event_rule': (values) => {
    const name = values.name;
    if (name) {
      try {
        execSync(`aws events describe-rule --name "${name}"`, { stdio: 'ignore' });
        return { exists: true, importId: name };
      } catch {
        return { exists: false };
      }
    }
    return { exists: null };
  },
  'aws_cloudwatch_event_target': (values) => {
    // Event targets are part of rules, check if rule exists
    const rule = values.rule;
    if (rule) {
      try {
        const output = execSync(
          `aws events list-targets-by-rule --rule "${rule}" --query "Targets[?Arn=='${values.arn || ''}']"`,
          { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }
        );
        const targets = JSON.parse(output);
        if (targets && targets.length > 0) {
          // Import format: rule_name/target_id
          const targetId = values.target_id || 'default';
          return { exists: true, importId: `${rule}/${targetId}` };
        }
      } catch {
        // Rule might not exist
      }
    }
    return { exists: null };
  },
  'aws_cloudwatch_metric_alarm': (values) => {
    const name = values.alarm_name || values.name;
    if (name) {
      try {
        execSync(`aws cloudwatch describe-alarms --alarm-names "${name}"`, { stdio: 'ignore' });
        return { exists: true, importId: name };
      } catch {
        return { exists: false };
      }
    }
    return { exists: null };
  },
  'aws_iam_role_policy': (values) => {
    // IAM role policies are attached to roles
    const roleName = values.role;
    const policyName = values.name;
    if (roleName && policyName) {
      try {
        execSync(`aws iam get-role-policy --role-name "${roleName}" --policy-name "${policyName}"`, { stdio: 'ignore' });
        return { exists: true, importId: `${roleName}:${policyName}` };
      } catch {
        return { exists: false };
      }
    }
    return { exists: null };
  },
  'aws_lambda_permission': (values) => {
    // Lambda permissions are tricky - they're identified by statement_id
    // Usually these are new unless we're recreating
    const functionName = values.function_name;
    const statementId = values.statement_id || 'AllowExecutionFromAPIGateway';
    if (functionName) {
      try {
        // Check if function exists first
        execSync(`aws lambda get-function --function-name "${functionName}"`, { stdio: 'ignore' });
        // Permission exists if function exists (can't easily check permission itself)
        // Most permissions are created fresh, so default to new
        return { exists: false };
      } catch {
        return { exists: false };
      }
    }
    return { exists: null };
  },
  'aws_s3_bucket_policy': (values) => {
    const bucket = values.bucket;
    if (bucket) {
      try {
        execSync(`aws s3api get-bucket-policy --bucket "${bucket}"`, { stdio: 'ignore' });
        return { exists: true, importId: bucket };
      } catch {
        return { exists: false };
      }
    }
    return { exists: null };
  },
  'aws_secretsmanager_secret_version': (values) => {
    // Secret versions are versioned - check if secret exists
    const secretId = values.secret_id || values.secret_arn;
    if (secretId) {
      try {
        execSync(`aws secretsmanager describe-secret --secret-id "${secretId}"`, { stdio: 'ignore' });
        // Secret exists, but version might be new - default to checking
        return { exists: null, importId: secretId };
      } catch {
        return { exists: false };
      }
    }
    return { exists: null };
  },
  'aws_sns_topic_subscription': (values) => {
    // SNS subscriptions are identified by ARN
    const arn = values.arn || values.subscription_arn;
    if (arn) {
      try {
        execSync(`aws sns get-subscription-attributes --subscription-arn "${arn}"`, { stdio: 'ignore' });
        return { exists: true, importId: arn };
      } catch {
        return { exists: false };
      }
    }
    return { exists: null };
  },
  'aws_wafv2_web_acl_association': (values) => {
    // WAF associations are identified by resource ARN + web ACL ARN
    const resourceArn = values.resource_arn;
    const webAclArn = values.web_acl_arn;
    if (resourceArn && webAclArn) {
      try {
        // Check if association exists (hard to check directly, but if resources exist, likely new)
        return { exists: false };
      } catch {
        return { exists: false };
      }
    }
    return { exists: null };
  },
  'aws_api_gateway_usage_plan_key': (values) => {
    // Usage plan keys are identified by usage_plan_id + key_id
    const usagePlanId = values.usage_plan_id;
    const keyId = values.key_id;
    if (usagePlanId && keyId) {
      try {
        execSync(`aws apigateway get-usage-plan-key --usage-plan-id "${usagePlanId}" --key-id "${keyId}"`, { stdio: 'ignore' });
        return { exists: true, importId: `${usagePlanId}/${keyId}` };
      } catch {
        return { exists: false };
      }
    }
    return { exists: null };
  },
  'null_resource': () => {
    // Null resources are always new - they're local-only
    return { exists: false };
  }
};

function extractResourceId(resourceType, values) {
  // Try common ID fields based on resource type
  switch (resourceType) {
    case 'aws_s3_bucket':
      return values.bucket || values.id;
    case 'aws_lambda_function':
      return values.function_name || values.id;
    case 'aws_cloudfront_distribution':
      return values.distribution_id || values.id;
    case 'aws_route53_zone':
      return values.zone_id || values.hosted_zone_id || values.id;
    case 'aws_route53_record':
      return values.name || values.fqdn || values.id;
    case 'aws_dynamodb_table':
      return values.table_name || values.name || values.id;
    case 'aws_iam_role':
      return values.role_name || values.name || values.id;
    case 'aws_sns_topic':
      return values.name || values.topic_arn || values.id;
    case 'aws_cloudwatch_dashboard':
      return values.dashboard_name || values.name || values.id;
    case 'aws_cloudwatch_event_rule':
      return values.name || values.id;
    case 'aws_cloudwatch_metric_alarm':
      return values.alarm_name || values.name || values.id;
    default:
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

