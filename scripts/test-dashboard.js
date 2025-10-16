#!/usr/bin/env node

/**
 * Dashboard Data Validation Test Script
 * Tests API endpoint and validates dashboard data
 */

const https = require('https');

// Test configuration
const API_URL = 'https://lbfggdldp3.execute-api.us-east-1.amazonaws.com/prod/dashboard-data';
const DASHBOARD_URL = 'https://robertconsulting.net/dashboard.html';

// Expected values
const EXPECTED_COST_TOTAL = 16.50;
const EXPECTED_SERVICES = ['s3', 'cloudfront', 'route53', 'waf', 'cloudwatch', 'lambda', 'ses', 'other'];

// Test results
let testResults = {
    apiEndpoint: { passed: 0, failed: 0, tests: [] },
    serviceHealth: { passed: 0, failed: 0, tests: [] },
    performanceMetrics: { passed: 0, failed: 0, tests: [] },
    costData: { passed: 0, failed: 0, tests: [] },
    githubStats: { passed: 0, failed: 0, tests: [] }
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
 * Test API endpoint response
 */
async function testApiEndpoint() {
    console.log('\n🔍 Testing API Endpoint...');
    
    try {
        const data = await makeRequest(API_URL);
        
        // Test 1: Response structure
        const hasRequiredSections = data.aws && data.traffic && data.health && 
                                   data.serviceHealth && data.performance && 
                                   data.github && data.velocity;
        
        if (hasRequiredSections) {
            testResults.apiEndpoint.passed++;
            testResults.apiEndpoint.tests.push('✅ Response has all required sections');
        } else {
            testResults.apiEndpoint.failed++;
            testResults.apiEndpoint.tests.push('❌ Missing required sections');
        }
        
        // Test 2: Generated timestamp
        const generatedAt = new Date(data.generatedAt);
        const now = new Date();
        const timeDiff = Math.abs(now - generatedAt);
        
        if (timeDiff < 60000) { // Within 1 minute
            testResults.apiEndpoint.passed++;
            testResults.apiEndpoint.tests.push('✅ Generated timestamp is recent');
        } else {
            testResults.apiEndpoint.failed++;
            testResults.apiEndpoint.tests.push('❌ Generated timestamp is too old');
        }
        
        return data;
        
    } catch (error) {
        testResults.apiEndpoint.failed++;
        testResults.apiEndpoint.tests.push(`❌ API request failed: ${error.message}`);
        return null;
    }
}

/**
 * Test service health data
 */
function testServiceHealth(data) {
    console.log('\n🏥 Testing Service Health...');
    
    if (!data || !data.serviceHealth) {
        testResults.serviceHealth.failed++;
        testResults.serviceHealth.tests.push('❌ No service health data');
        return;
    }
    
    const services = ['s3', 'cloudfront', 'lambda', 'route53', 'website'];
    let allHealthy = true;
    
    services.forEach(service => {
        if (data.serviceHealth[service] && data.serviceHealth[service].status === 'healthy') {
            testResults.serviceHealth.passed++;
            testResults.serviceHealth.tests.push(`✅ ${service} is healthy`);
        } else {
            testResults.serviceHealth.failed++;
            testResults.serviceHealth.tests.push(`❌ ${service} is not healthy`);
            allHealthy = false;
        }
    });
    
    if (allHealthy) {
        testResults.serviceHealth.passed++;
        testResults.serviceHealth.tests.push('✅ All services show healthy status');
    } else {
        testResults.serviceHealth.failed++;
        testResults.serviceHealth.tests.push('❌ Some services are not healthy');
    }
}

/**
 * Test performance metrics
 */
function testPerformanceMetrics(data) {
    console.log('\n⚡ Testing Performance Metrics...');
    
    if (!data || !data.performance) {
        testResults.performanceMetrics.failed++;
        testResults.performanceMetrics.tests.push('❌ No performance data');
        return;
    }
    
    const perf = data.performance;
    
    // Test response time
    if (perf.resourceTiming && perf.resourceTiming.ttfb) {
        const ttfb = parseInt(perf.resourceTiming.ttfb);
        if (ttfb >= 100 && ttfb <= 1000) {
            testResults.performanceMetrics.passed++;
            testResults.performanceMetrics.tests.push(`✅ TTFB is reasonable: ${perf.resourceTiming.ttfb}`);
        } else {
            testResults.performanceMetrics.failed++;
            testResults.performanceMetrics.tests.push(`❌ TTFB is unreasonable: ${perf.resourceTiming.ttfb}`);
        }
    }
    
    // Test Core Web Vitals
    if (perf.coreWebVitals && perf.coreWebVitals.lcp) {
        testResults.performanceMetrics.passed++;
        testResults.performanceMetrics.tests.push(`✅ Core Web Vitals present: LCP ${perf.coreWebVitals.lcp.value}`);
    } else {
        testResults.performanceMetrics.failed++;
        testResults.performanceMetrics.tests.push('❌ Core Web Vitals missing');
    }
}

/**
 * Test cost data
 */
function testCostData(data) {
    console.log('\n💰 Testing Cost Data...');
    
    if (!data || !data.aws) {
        testResults.costData.failed++;
        testResults.costData.tests.push('❌ No cost data');
        return;
    }
    
    const aws = data.aws;
    
    // Test total cost
    if (aws.monthlyCostTotal === EXPECTED_COST_TOTAL) {
        testResults.costData.passed++;
        testResults.costData.tests.push(`✅ Monthly cost is correct: $${aws.monthlyCostTotal}`);
    } else {
        testResults.costData.failed++;
        testResults.costData.tests.push(`❌ Monthly cost is incorrect: $${aws.monthlyCostTotal} (expected $${EXPECTED_COST_TOTAL})`);
    }
    
    // Test individual services
    if (aws.services) {
        EXPECTED_SERVICES.forEach(service => {
            if (aws.services[service] !== undefined) {
                testResults.costData.passed++;
                testResults.costData.tests.push(`✅ ${service} cost present: $${aws.services[service]}`);
            } else {
                testResults.costData.failed++;
                testResults.costData.tests.push(`❌ ${service} cost missing`);
            }
        });
    }
}

/**
 * Test GitHub statistics
 */
function testGitHubStats(data) {
    console.log('\n📊 Testing GitHub Statistics...');
    
    if (!data || !data.github) {
        testResults.githubStats.failed++;
        testResults.githubStats.tests.push('❌ No GitHub data');
        return;
    }
    
    const github = data.github;
    
    // Test commits
    if (github.commits && github.commits.last7Days >= 0) {
        testResults.githubStats.passed++;
        testResults.githubStats.tests.push(`✅ 7-day commits: ${github.commits.last7Days}`);
    } else {
        testResults.githubStats.failed++;
        testResults.githubStats.tests.push('❌ 7-day commits missing or invalid');
    }
    
    // Test development activity
    if (github.development && github.development.features >= 0) {
        testResults.githubStats.passed++;
        testResults.githubStats.tests.push(`✅ Development activity present: ${github.development.features} features`);
    } else {
        testResults.githubStats.failed++;
        testResults.githubStats.tests.push('❌ Development activity missing');
    }
}

/**
 * Test dynamic values
 */
async function testDynamicValues() {
    console.log('\n🔄 Testing Dynamic Values...');
    
    const values1 = await makeRequest(API_URL);
    await new Promise(resolve => setTimeout(resolve, 1000));
    const values2 = await makeRequest(API_URL);
    
    if (values1 && values2) {
        const ttfb1 = values1.performance?.resourceTiming?.ttfb;
        const ttfb2 = values2.performance?.resourceTiming?.ttfb;
        
        if (ttfb1 !== ttfb2) {
            testResults.performanceMetrics.passed++;
            testResults.performanceMetrics.tests.push(`✅ Response time is dynamic: ${ttfb1} → ${ttfb2}`);
        } else {
            testResults.performanceMetrics.failed++;
            testResults.performanceMetrics.tests.push(`❌ Response time is static: ${ttfb1}`);
        }
        
        const commits1 = values1.github?.commits?.last7Days;
        const commits2 = values2.github?.commits?.last7Days;
        
        if (commits1 !== commits2) {
            testResults.githubStats.passed++;
            testResults.githubStats.tests.push(`✅ Commit count is dynamic: ${commits1} → ${commits2}`);
        } else {
            testResults.githubStats.failed++;
            testResults.githubStats.tests.push(`❌ Commit count is static: ${commits1}`);
        }
    }
}

/**
 * Print test results
 */
function printResults() {
    console.log('\n📋 TEST RESULTS SUMMARY');
    console.log('========================');
    
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
    
    if (overallPercentage >= 90) {
        console.log('✅ Dashboard validation PASSED!');
        process.exit(0);
    } else {
        console.log('❌ Dashboard validation FAILED!');
        process.exit(1);
    }
}

/**
 * Main test execution
 */
async function runTests() {
    console.log('🚀 Starting Dashboard Data Validation Tests...');
    
    try {
        const data = await testApiEndpoint();
        testServiceHealth(data);
        testPerformanceMetrics(data);
        testCostData(data);
        testGitHubStats(data);
        await testDynamicValues();
        printResults();
    } catch (error) {
        console.error('❌ Test execution failed:', error.message);
        process.exit(1);
    }
}

// Run tests
runTests();
