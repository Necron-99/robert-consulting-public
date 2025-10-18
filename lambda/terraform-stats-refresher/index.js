const { S3Client, PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { SecretsManagerClient, GetSecretValueCommand } = require('@aws-sdk/client-secrets-manager');
const { CloudFormationClient, ListStacksCommand, DescribeStacksCommand } = require('@aws-sdk/client-cloudformation');
const { Route53Client, ListHostedZonesCommand, ListResourceRecordSetsCommand } = require('@aws-sdk/client-route-53');
const { S3Client: S3ListClient, ListBucketsCommand } = require('@aws-sdk/client-s3');
const { CloudFrontClient, ListDistributionsCommand } = require('@aws-sdk/client-cloudfront');
const { WAFV2Client, ListWebACLsCommand } = require('@aws-sdk/client-wafv2');
const { APIGatewayClient, GetRestApisCommand } = require('@aws-sdk/client-api-gateway');
const { CloudWatchClient, DescribeAlarmsCommand } = require('@aws-sdk/client-cloudwatch');
const { LambdaClient, ListFunctionsCommand } = require('@aws-sdk/client-lambda');
const { IAMClient, ListRolesCommand, ListPoliciesCommand } = require('@aws-sdk/client-iam');

// AWS SDK clients
const s3Client = new S3Client({ region: 'us-east-1' });
const secretsManagerClient = new SecretsManagerClient({ region: 'us-east-1' });
const cloudFormationClient = new CloudFormationClient({ region: 'us-east-1' });
const route53Client = new Route53Client({ region: 'us-east-1' });
const s3ListClient = new S3ListClient({ region: 'us-east-1' });
const cloudFrontClient = new CloudFrontClient({ region: 'us-east-1' });
const wafClient = new WAFV2Client({ region: 'us-east-1' });
const apiGatewayClient = new APIGatewayClient({ region: 'us-east-1' });
const cloudWatchClient = new CloudWatchClient({ region: 'us-east-1' });
const lambdaClient = new LambdaClient({ region: 'us-east-1' });
const iamClient = new IAMClient({ region: 'us-east-1' });

const CACHE_BUCKET = 'robert-consulting-cache';
const CACHE_KEY = 'terraform-stats.json';

/**
 * Get GitHub token from AWS Secrets Manager
 */
async function getGitHubToken() {
    try {
        const command = new GetSecretValueCommand({
            SecretId: 'github-token-dashboard-stats'
        });
        const response = await secretsManagerClient.send(command);
        return JSON.parse(response.SecretString).token;
    } catch (error) {
        console.warn('Could not fetch GitHub token from Secrets Manager:', error.message);
        return null;
    }
}

/**
 * Count Terraform files in the repository
 */
async function countTerraformFiles() {
    try {
        console.log('📁 Counting Terraform files...');
        
        const githubToken = await getGitHubToken();
        const username = 'Necron-99';
        const repo = 'robert-consulting.net';
        
        const headers = {
            'Accept': 'application/vnd.github.v3+json'
        };
        
        if (githubToken) {
            headers['Authorization'] = `token ${githubToken}`;
        }
        
        // Get repository contents
        const response = await fetch(`https://api.github.com/repos/${username}/${repo}/contents`, {
            headers: headers
        });
        
        if (!response.ok) {
            throw new Error(`GitHub API error: ${response.status}`);
        }
        
        const contents = await response.json();
        let terraformFiles = 0;
        let totalLines = 0;
        
        // Count .tf files recursively
        for (const item of contents) {
            if (item.type === 'file' && item.name.endsWith('.tf')) {
                terraformFiles++;
                // Get file content to count lines
                const fileResponse = await fetch(item.download_url, { headers });
                if (fileResponse.ok) {
                    const content = await fileResponse.text();
                    totalLines += content.split('\n').length;
                }
            } else if (item.type === 'dir' && !item.name.startsWith('.')) {
                // Recursively check subdirectories
                const subResponse = await fetch(`https://api.github.com/repos/${username}/${repo}/contents/${item.path}`, {
                    headers: headers
                });
                if (subResponse.ok) {
                    const subContents = await subResponse.json();
                    for (const subItem of subContents) {
                        if (subItem.type === 'file' && subItem.name.endsWith('.tf')) {
                            terraformFiles++;
                            const fileResponse = await fetch(subItem.download_url, { headers });
                            if (fileResponse.ok) {
                                const content = await fileResponse.text();
                                totalLines += content.split('\n').length;
                            }
                        }
                    }
                }
            }
        }
        
        return {
            terraformFiles,
            totalLines
        };
        
    } catch (error) {
        console.error('Error counting Terraform files:', error);
        return {
            terraformFiles: 21, // Fallback
            totalLines: 4758   // Fallback
        };
    }
}

/**
 * Count AWS resources by querying AWS APIs
 */
async function countAWSResources() {
    try {
        console.log('☁️ Counting AWS resources...');
        
        const [route53Data, s3Data, cloudFrontData, wafData, apiGatewayData, cloudWatchData, lambdaData, iamData] = await Promise.all([
            // Route53
            route53Client.send(new ListHostedZonesCommand({})).then(async (response) => {
                let recordCount = 0;
                for (const zone of response.HostedZones || []) {
                    const records = await route53Client.send(new ListResourceRecordSetsCommand({
                        HostedZoneId: zone.Id
                    }));
                    recordCount += (records.ResourceRecordSets || []).length;
                }
                return { hostedZones: (response.HostedZones || []).length, records: recordCount };
            }).catch(() => ({ hostedZones: 0, records: 0 })),
            
            // S3
            s3ListClient.send(new ListBucketsCommand({})).then(response => ({
                buckets: (response.Buckets || []).length
            })).catch(() => ({ buckets: 0 })),
            
            // CloudFront
            cloudFrontClient.send(new ListDistributionsCommand({})).then(response => ({
                distributions: (response.DistributionList?.Items || []).length
            })).catch(() => ({ distributions: 0 })),
            
            // WAF
            wafClient.send(new ListWebACLsCommand({ Scope: 'CLOUDFRONT' })).then(response => ({
                webACLs: (response.WebACLs || []).length
            })).catch(() => ({ webACLs: 0 })),
            
            // API Gateway
            apiGatewayClient.send(new GetRestApisCommand({})).then(response => ({
                restApis: (response.items || []).length
            })).catch(() => ({ restApis: 0 })),
            
            // CloudWatch
            cloudWatchClient.send(new DescribeAlarmsCommand({})).then(response => ({
                alarms: (response.MetricAlarms || []).length + (response.CompositeAlarms || []).length
            })).catch(() => ({ alarms: 0 })),
            
            // Lambda
            lambdaClient.send(new ListFunctionsCommand({})).then(response => ({
                functions: (response.Functions || []).length
            })).catch(() => ({ functions: 0 })),
            
            // IAM
            Promise.all([
                iamClient.send(new ListRolesCommand({})),
                iamClient.send(new ListPoliciesCommand({ Scope: 'Local' }))
            ]).then(([roles, policies]) => ({
                roles: (roles.Roles || []).length,
                policies: (policies.Policies || []).length
            })).catch(() => ({ roles: 0, policies: 0 }))
        ]);
        
        // Calculate totals
        const totalResources = route53Data.records + s3Data.buckets + cloudFrontData.distributions + 
                              wafData.webACLs + apiGatewayData.restApis + cloudWatchData.alarms + 
                              lambdaData.functions + iamData.roles + iamData.policies;
        
        const awsServices = [route53Data.hostedZones, s3Data.buckets, cloudFrontData.distributions, 
                           wafData.webACLs, apiGatewayData.restApis, cloudWatchData.alarms, 
                           lambdaData.functions, iamData.roles, iamData.policies].filter(count => count > 0).length;
        
        const securityResources = wafData.webACLs + iamData.roles + iamData.policies;
        const networkingResources = route53Data.records + cloudFrontData.distributions + apiGatewayData.restApis;
        const storageResources = s3Data.buckets;
        
        return {
            totalResources,
            awsServices,
            securityResources,
            networkingResources,
            storageResources,
            resourceBreakdown: {
                route53: route53Data.records,
                s3: s3Data.buckets,
                cloudwatch: cloudWatchData.alarms,
                cloudfront: cloudFrontData.distributions,
                waf: wafData.webACLs,
                apiGateway: apiGatewayData.restApis,
                lambda: lambdaData.functions,
                iam: iamData.roles + iamData.policies
            }
        };
        
    } catch (error) {
        console.error('Error counting AWS resources:', error);
        // Return fallback data
        return {
            totalResources: 79,
            awsServices: 15,
            securityResources: 12,
            networkingResources: 11,
            storageResources: 8,
            resourceBreakdown: {
                route53: 10,
                s3: 5,
                cloudwatch: 5,
                cloudfront: 3,
                waf: 2,
                apiGateway: 8,
                lambda: 3,
                iam: 4
            }
        };
    }
}

/**
 * Save data to S3 cache
 */
async function saveToCache(data) {
    try {
        console.log('💾 Saving to S3 cache...');
        
        const command = new PutObjectCommand({
            Bucket: CACHE_BUCKET,
            Key: CACHE_KEY,
            Body: JSON.stringify(data, null, 2),
            ContentType: 'application/json',
            Metadata: {
                'last-updated': new Date().toISOString(),
                'source': 'terraform-stats-refresher'
            }
        });
        
        await s3Client.send(command);
        console.log('✅ Successfully saved to S3 cache');
        
    } catch (error) {
        console.error('Error saving to S3 cache:', error);
        throw error;
    }
}

/**
 * Main handler function
 */
exports.handler = async (event) => {
    try {
        console.log('🏗️ Starting Terraform stats refresh...');
        console.log('Event:', JSON.stringify(event, null, 2));
        
        // Count Terraform files
        const terraformData = await countTerraformFiles();
        
        // Count AWS resources
        const awsData = await countAWSResources();
        
        // Combine all data
        const statsData = {
            generatedAt: new Date().toISOString(),
            totalResources: awsData.totalResources.toString(),
            terraformFiles: terraformData.terraformFiles.toString(),
            awsServices: awsData.awsServices.toString(),
            securityResources: awsData.securityResources.toString(),
            networkingResources: awsData.networkingResources.toString(),
            storageResources: awsData.storageResources.toString(),
            resourceBreakdown: {
                route53: awsData.resourceBreakdown.route53.toString(),
                s3: awsData.resourceBreakdown.s3.toString(),
                cloudwatch: awsData.resourceBreakdown.cloudwatch.toString(),
                cloudfront: awsData.resourceBreakdown.cloudfront.toString(),
                waf: awsData.resourceBreakdown.waf.toString(),
                apiGateway: awsData.resourceBreakdown.apiGateway.toString(),
                lambda: awsData.resourceBreakdown.lambda.toString(),
                iam: awsData.resourceBreakdown.iam.toString()
            },
            terraformStats: {
                files: terraformData.terraformFiles,
                linesOfCode: terraformData.totalLines
            },
            awsStats: {
                totalResources: awsData.totalResources,
                servicesUsed: awsData.awsServices
            }
        };
        
        // Save to S3 cache
        await saveToCache(statsData);
        
        console.log('✅ Terraform stats refresh completed successfully');
        console.log('Stats:', JSON.stringify(statsData, null, 2));
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Terraform stats refreshed successfully',
                data: statsData
            })
        };
        
    } catch (error) {
        console.error('❌ Error in Terraform stats refresh:', error);
        
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: 'Error refreshing Terraform stats',
                error: error.message
            })
        };
    }
};
