#!/usr/bin/env node

/**
 * Strict Dashboard Data Validation Test Script
 * Tests API endpoint and validates dashboard data with strict failure conditions
 */

const https = require('https');

// Test configuration
const API_URL = 'https://lbfggdldp3.execute-api.us-east-1.amazonaws.com/prod/dashboard-data';
const DASHBOARD_URL = 'https://robertconsulting.net/dashboard.html';

// Expected values - these must match exactly or test fails
const EXPECTED_COST_TOTAL = 16.50;
const EXPECTED_SERVICES = ['s3', 'cloudfront', 'route53', 'waf', 'cloudwatch', 'lambda', 'ses', 'other'];

// Test results
let testResults = {
    apiEndpoint: { passed: 0, failed: 0, tests: [] },
    systemStatus: { passed: 0, failed: 0, tests: [] },
    performanceMetrics: { passed: 0, failed: 0, tests: [] },
    costData: { passed: 0, failed: 0, tests: [] },
    githubStats: { passed: 0, failed: 0, tests: [] },
    dataIntegrity: { passed: 0, failed: 0, tests: [] }
};

/**
 * Make HTTP request
 */
function makeRequest(url) {
    return new Promise((resolve, reject) => {
        https.get(url, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                try {
                    resolve(JSON.parse(data));
                } catch (e) {
                    reject(new Error('Invalid JSON response'));
                }
            });
        }).on('error', reject);
    });
}

/**
 * Test API endpoint response with strict validation
 */
async function testApiEndpoint() {
    console.log('\n🔍 Testing API Endpoint (Strict Mode)...');
    
    try {
        const data = await makeRequest(API_URL);
        
        // Test 1: Response structure - MUST have all required sections
        const requiredSections = ['aws', 'traffic', 'health', 'performance', 'github', 'velocity'];
        const missingSections = requiredSections.filter(section => !data[section]);
        
        if (missingSections.length === 0) {
            testResults.apiEndpoint.passed++;
            testResults.apiEndpoint.tests.push('✅ Response has all required sections');
        } else {
            testResults.apiEndpoint.failed++;
            testResults.apiEndpoint.tests.push(`❌ Missing required sections: ${missingSections.join(', ')}`);
        }
        
        // Test 2: Generated timestamp - MUST be recent (within 5 minutes)
        const generatedAt = new Date(data.generatedAt);
        const now = new Date();
        const timeDiff = Math.abs(now - generatedAt);
        
        if (timeDiff < 300000) { // Within 5 minutes
            testResults.apiEndpoint.passed++;
            testResults.apiEndpoint.tests.push('✅ Generated timestamp is recent');
        } else {
            testResults.apiEndpoint.failed++;
            testResults.apiEndpoint.tests.push(`❌ Generated timestamp is too old: ${Math.round(timeDiff / 60000)} minutes ago`);
        }
        
        return data;
        
    } catch (error) {
        testResults.apiEndpoint.failed++;
        testResults.apiEndpoint.tests.push(`❌ API request failed: ${error.message}`);
        return null;
    }
}

/**
 * Test system status data (replaces service health) with strict validation
 */
function testSystemStatus(data) {
    console.log('\n🏥 Testing System Status (Strict Mode)...');
    
    if (!data || !data.health) {
        testResults.systemStatus.failed++;
        testResults.systemStatus.tests.push('❌ No system status data');
        return;
    }
    
    // Test site health - MUST be healthy
    if (data.health.site && data.health.site.status === 'healthy') {
        testResults.systemStatus.passed++;
        testResults.systemStatus.tests.push('✅ Site status is healthy');
    } else {
        testResults.systemStatus.failed++;
        testResults.systemStatus.tests.push(`❌ Site status is not healthy: ${data.health.site?.status || 'missing'}`);
    }
    
    // Test Route53 health - MUST have active queries
    if (data.health.route53 && data.health.route53.queries24h > 0) {
        testResults.systemStatus.passed++;
        testResults.systemStatus.tests.push(`✅ Route53 queries are active: ${data.health.route53.queries24h.toLocaleString()}`);
    } else {
        testResults.systemStatus.failed++;
        testResults.systemStatus.tests.push(`❌ Route53 queries are not active: ${data.health.route53?.queries24h || 'missing'}`);
    }
    
    // Test response time - MUST be reasonable (100-500ms)
    if (data.health.site && data.health.site.responseMs && 
        data.health.site.responseMs >= 100 && data.health.site.responseMs <= 500) {
        testResults.systemStatus.passed++;
        testResults.systemStatus.tests.push(`✅ Response time is reasonable: ${data.health.site.responseMs}ms`);
    } else {
        testResults.systemStatus.failed++;
        testResults.systemStatus.tests.push(`❌ Response time is unreasonable: ${data.health.site?.responseMs || 'missing'}ms (expected 100-500ms)`);
    }
}

/**
 * Test performance metrics with strict validation
 */
function testPerformanceMetrics(data) {
    console.log('\n⚡ Testing Performance Metrics (Strict Mode)...');
    
    if (!data || !data.performance) {
        testResults.performanceMetrics.failed++;
        testResults.performanceMetrics.tests.push('❌ No performance data');
        return;
    }
    
    const perf = data.performance;
    
    // Test response time - MUST be in reasonable range
    if (perf.resourceTiming && perf.resourceTiming.ttfb) {
        const ttfb = parseInt(perf.resourceTiming.ttfb);
        if (ttfb >= 100 && ttfb <= 500) {
            testResults.performanceMetrics.passed++;
            testResults.performanceMetrics.tests.push(`✅ TTFB is reasonable: ${perf.resourceTiming.ttfb}`);
        } else {
            testResults.performanceMetrics.failed++;
            testResults.performanceMetrics.tests.push(`❌ TTFB is unreasonable: ${perf.resourceTiming.ttfb} (expected 100-500ms)`);
        }
    } else {
        testResults.performanceMetrics.failed++;
        testResults.performanceMetrics.tests.push('❌ TTFB data missing');
    }
    
    // Test Core Web Vitals - MUST be present and reasonable
    if (perf.coreWebVitals && perf.coreWebVitals.lcp) {
        const lcp = parseFloat(perf.coreWebVitals.lcp.value);
        if (lcp >= 0.5 && lcp <= 2.5) {
            testResults.performanceMetrics.passed++;
            testResults.performanceMetrics.tests.push(`✅ LCP is reasonable: ${perf.coreWebVitals.lcp.value}`);
        } else {
            testResults.performanceMetrics.failed++;
            testResults.performanceMetrics.tests.push(`❌ LCP is unreasonable: ${perf.coreWebVitals.lcp.value} (expected 0.5-2.5s)`);
        }
    } else {
        testResults.performanceMetrics.failed++;
        testResults.performanceMetrics.tests.push('❌ Core Web Vitals missing');
    }
}

/**
 * Test cost data with strict validation
 */
function testCostData(data) {
    console.log('\n💰 Testing Cost Data (Strict Mode)...');
    
    if (!data || !data.aws) {
        testResults.costData.failed++;
        testResults.costData.tests.push('❌ No cost data');
        return;
    }
    
    const aws = data.aws;
    
    // Test total cost - MUST match expected value exactly
    if (aws.monthlyCostTotal === EXPECTED_COST_TOTAL) {
        testResults.costData.passed++;
        testResults.costData.tests.push(`✅ Monthly cost is correct: $${aws.monthlyCostTotal}`);
    } else {
        testResults.costData.failed++;
        testResults.costData.tests.push(`❌ Monthly cost is incorrect: $${aws.monthlyCostTotal} (expected $${EXPECTED_COST_TOTAL})`);
    }
    
    // Test individual services - MUST all be present and positive
    EXPECTED_SERVICES.forEach(service => {
        if (aws.services[service] !== undefined && aws.services[service] >= 0) {
            testResults.costData.passed++;
            testResults.costData.tests.push(`✅ ${service} cost present: $${aws.services[service]}`);
        } else {
            testResults.costData.failed++;
            testResults.costData.tests.push(`❌ ${service} cost missing or negative: $${aws.services[service] || 'undefined'}`);
        }
    });
}

/**
 * Test GitHub statistics with strict validation
 */
function testGitHubStats(data) {
    console.log('\n📊 Testing GitHub Statistics (Strict Mode)...');
    
    if (!data || !data.github) {
        testResults.githubStats.failed++;
        testResults.githubStats.tests.push('❌ No GitHub data');
        return;
    }
    
    const github = data.github;
    
    // Test commits - MUST be positive numbers
    if (github.commits && github.commits.last7Days >= 0 && github.commits.last30Days >= 0) {
        testResults.githubStats.passed++;
        testResults.githubStats.tests.push(`✅ 7-day commits: ${github.commits.last7Days}, 30-day: ${github.commits.last30Days}`);
    } else {
        testResults.githubStats.failed++;
        testResults.githubStats.tests.push(`❌ Commit data invalid: 7d=${github.commits?.last7Days || 'missing'}, 30d=${github.commits?.last30Days || 'missing'}`);
    }
    
    // Test development activity - MUST be present
    if (github.development && github.development.features >= 0 && github.development.bugFixes >= 0) {
        testResults.githubStats.passed++;
        testResults.githubStats.tests.push(`✅ Development activity present: ${github.development.features} features, ${github.development.bugFixes} bug fixes`);
    } else {
        testResults.githubStats.failed++;
        testResults.githubStats.tests.push(`❌ Development activity missing or invalid`);
    }
}

/**
 * Test data integrity with strict validation
 */
function testDataIntegrity(data) {
    console.log('\n🔍 Testing Data Integrity (Strict Mode)...');
    
    if (!data) {
        testResults.dataIntegrity.failed++;
        testResults.dataIntegrity.tests.push('❌ No data received');
        return;
    }
    
    // Test for null/undefined values in critical fields
    const criticalFields = [
        'aws.monthlyCostTotal',
        'health.site.status',
        'performance.resourceTiming.ttfb',
        'github.commits.last7Days'
    ];
    
    let hasNullValues = false;
    criticalFields.forEach(field => {
        const value = field.split('.').reduce((obj, key) => obj?.[key], data);
        if (value === null || value === undefined) {
            testResults.dataIntegrity.failed++;
            testResults.dataIntegrity.tests.push(`❌ Critical field is null/undefined: ${field}`);
            hasNullValues = true;
        }
    });
    
    if (!hasNullValues) {
        testResults.dataIntegrity.passed++;
        testResults.dataIntegrity.tests.push('✅ No null/undefined values in critical fields');
    }
    
    // Test for reasonable data ranges
    if (data.aws && data.aws.monthlyCostTotal > 0 && data.aws.monthlyCostTotal < 1000) {
        testResults.dataIntegrity.passed++;
        testResults.dataIntegrity.tests.push('✅ Cost data is in reasonable range');
    } else {
        testResults.dataIntegrity.failed++;
        testResults.dataIntegrity.tests.push(`❌ Cost data is unreasonable: $${data.aws?.monthlyCostTotal || 'missing'}`);
    }
}

/**
 * Test dynamic values with strict validation
 */
async function testDynamicValues() {
    console.log('\n🔄 Testing Dynamic Values (Strict Mode)...');
    
    const values1 = await makeRequest(API_URL);
    await new Promise(resolve => setTimeout(resolve, 2000)); // Wait 2 seconds
    const values2 = await makeRequest(API_URL);
    
    if (values1 && values2) {
        // Test response time changes
        const ttfb1 = values1.performance?.resourceTiming?.ttfb;
        const ttfb2 = values2.performance?.resourceTiming?.ttfb;
        
        if (ttfb1 !== ttfb2) {
            testResults.performanceMetrics.passed++;
            testResults.performanceMetrics.tests.push(`✅ Response time is dynamic: ${ttfb1} → ${ttfb2}`);
        } else {
            testResults.performanceMetrics.failed++;
            testResults.performanceMetrics.tests.push(`❌ Response time is static: ${ttfb1}`);
        }
        
        // Test commit count changes
        const commits1 = values1.github?.commits?.last7Days;
        const commits2 = values2.github?.commits?.last7Days;
        
        if (commits1 !== commits2) {
            testResults.githubStats.passed++;
            testResults.githubStats.tests.push(`✅ Commit count is dynamic: ${commits1} → ${commits2}`);
        } else {
            testResults.githubStats.failed++;
            testResults.githubStats.tests.push(`❌ Commit count is static: ${commits1}`);
        }
    } else {
        testResults.performanceMetrics.failed++;
        testResults.performanceMetrics.tests.push('❌ Could not test dynamic values - API requests failed');
    }
}

/**
 * Print test results with strict failure conditions
 */
function printResults() {
    console.log('\n📋 STRICT DASHBOARD TEST RESULTS');
    console.log('==================================');
    
    Object.keys(testResults).forEach(category => {
        const result = testResults[category];
        const total = result.passed + result.failed;
        const percentage = total > 0 ? Math.round((result.passed / total) * 100) : 0;
        
        console.log(`\n${category.toUpperCase()}: ${result.passed}/${total} passed (${percentage}%)`);
        result.tests.forEach(test => console.log(`  ${test}`));
    });
    
    const totalPassed = Object.values(testResults).reduce((sum, r) => sum + r.passed, 0);
    const totalFailed = Object.values(testResults).reduce((sum, r) => sum + r.failed, 0);
    const totalTests = totalPassed + totalFailed;
    const overallPercentage = totalTests > 0 ? Math.round((totalPassed / totalTests) * 100) : 0;
    
    console.log(`\n🎯 OVERALL: ${totalPassed}/${totalTests} tests passed (${overallPercentage}%)`);
    
    // STRICT FAILURE CONDITIONS
    if (totalFailed > 0) {
        console.log('❌ DASHBOARD VALIDATION FAILED - Strict mode requires 100% pass rate!');
        console.log('🔍 Failed tests must be fixed before deployment.');
        process.exit(1);
    } else if (overallPercentage < 100) {
        console.log('❌ DASHBOARD VALIDATION FAILED - Not all tests passed!');
        process.exit(1);
    } else {
        console.log('✅ DASHBOARD VALIDATION PASSED - All tests passed in strict mode!');
        process.exit(0);
    }
}

/**
 * Main test execution
 */
async function runTests() {
    console.log('🚀 Starting Strict Dashboard Data Validation Tests...');
    console.log('⚠️  STRICT MODE: Any failed test will cause deployment to fail!');
    
    try {
        const data = await testApiEndpoint();
        testSystemStatus(data);
        testPerformanceMetrics(data);
        testCostData(data);
        testGitHubStats(data);
        testDataIntegrity(data);
        await testDynamicValues();
        printResults();
    } catch (error) {
        console.error('❌ Test execution failed:', error.message);
        process.exit(1);
    }
}

// Run tests
runTests();
