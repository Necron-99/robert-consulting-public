#!/usr/bin/env node

/**
 * Dashboard UI Validation Test Script
 * Tests the actual dashboard page to verify UI elements are updated correctly
 */

const https = require('https');

// Test configuration
const DASHBOARD_URL = 'https://robertconsulting.net/dashboard.html';
const API_URL = 'https://lbfggdldp3.execute-api.us-east-1.amazonaws.com/prod/dashboard-data';

// Test results
let testResults = {
    pageAccessibility: { passed: 0, failed: 0, tests: [] },
    scriptLoading: { passed: 0, failed: 0, tests: [] },
    apiIntegration: { passed: 0, failed: 0, tests: [] },
    healthStatusUI: { passed: 0, failed: 0, tests: [] }
};

/**
 * Make HTTP request
 */
function makeRequest(url) {
    return new Promise((resolve, reject) => {
        https.get(url, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => resolve({ status: res.statusCode, data }));
        }).on('error', reject);
    });
}

/**
 * Test dashboard page accessibility
 */
async function testPageAccessibility() {
    console.log('\n🌐 Testing Dashboard Page Accessibility...');
    
    try {
        const response = await makeRequest(DASHBOARD_URL);
        
        if (response.status === 200) {
            testResults.pageAccessibility.passed++;
            testResults.pageAccessibility.tests.push('✅ Dashboard page loads successfully (200 OK)');
        } else {
            testResults.pageAccessibility.failed++;
            testResults.pageAccessibility.tests.push(`❌ Dashboard page failed to load (${response.status})`);
        }
        
        // Check if page contains expected elements
        if (response.data.includes('SERVICE HEALTH')) {
            testResults.pageAccessibility.passed++;
            testResults.pageAccessibility.tests.push('✅ Service Health section present');
        } else {
            testResults.pageAccessibility.failed++;
            testResults.pageAccessibility.tests.push('❌ Service Health section missing');
        }
        
        if (response.data.includes('dashboard-script.js')) {
            testResults.pageAccessibility.passed++;
            testResults.pageAccessibility.tests.push('✅ Correct script file referenced (dashboard-script.js)');
        } else {
            testResults.pageAccessibility.failed++;
            testResults.pageAccessibility.tests.push('❌ Wrong or missing script file reference');
        }
        
        return response.data;
        
    } catch (error) {
        testResults.pageAccessibility.failed++;
        testResults.pageAccessibility.tests.push(`❌ Page accessibility test failed: ${error.message}`);
        return null;
    }
}

/**
 * Test script loading
 */
async function testScriptLoading() {
    console.log('\n📜 Testing Script Loading...');
    
    try {
        const response = await makeRequest('https://robertconsulting.net/dashboard-script.js');
        
        if (response.status === 200) {
            testResults.scriptLoading.passed++;
            testResults.scriptLoading.tests.push('✅ Dashboard script loads successfully (200 OK)');
        } else {
            testResults.scriptLoading.failed++;
            testResults.scriptLoading.tests.push(`❌ Dashboard script failed to load (${response.status})`);
        }
        
        // Check if script contains expected functions
        if (response.data.includes('loadHealthData')) {
            testResults.scriptLoading.passed++;
            testResults.scriptLoading.tests.push('✅ loadHealthData function present');
        } else {
            testResults.scriptLoading.failed++;
            testResults.scriptLoading.tests.push('❌ loadHealthData function missing');
        }
        
        if (response.data.includes('updateHealthStatus')) {
            testResults.scriptLoading.passed++;
            testResults.scriptLoading.tests.push('✅ updateHealthStatus function present');
        } else {
            testResults.scriptLoading.failed++;
            testResults.scriptLoading.tests.push('❌ updateHealthStatus function missing');
        }
        
        // Check for duplicate functions
        const updateHealthStatusCount = (response.data.match(/updateHealthStatus/g) || []).length;
        if (updateHealthStatusCount === 1) {
            testResults.scriptLoading.passed++;
            testResults.scriptLoading.tests.push('✅ No duplicate updateHealthStatus functions');
        } else {
            testResults.scriptLoading.failed++;
            testResults.scriptLoading.tests.push(`❌ Found ${updateHealthStatusCount} updateHealthStatus functions (should be 1)`);
        }
        
    } catch (error) {
        testResults.scriptLoading.failed++;
        testResults.scriptLoading.tests.push(`❌ Script loading test failed: ${error.message}`);
    }
}

/**
 * Test API integration
 */
async function testApiIntegration() {
    console.log('\n🔌 Testing API Integration...');
    
    try {
        const response = await makeRequest(API_URL);
        
        if (response.status === 200) {
            testResults.apiIntegration.passed++;
            testResults.apiIntegration.tests.push('✅ API endpoint accessible (200 OK)');
        } else {
            testResults.apiIntegration.failed++;
            testResults.apiIntegration.tests.push(`❌ API endpoint failed (${response.status})`);
        }
        
        const data = JSON.parse(response.data);
        
        // Check if API returns health data
        if (data.serviceHealth) {
            testResults.apiIntegration.passed++;
            testResults.apiIntegration.tests.push('✅ API returns serviceHealth data');
        } else {
            testResults.apiIntegration.failed++;
            testResults.apiIntegration.tests.push('❌ API missing serviceHealth data');
        }
        
        // Check if all services are healthy
        const services = ['s3', 'cloudfront', 'lambda', 'route53', 'website'];
        let allHealthy = true;
        
        services.forEach(service => {
            if (data.serviceHealth[service] && data.serviceHealth[service].status === 'healthy') {
                testResults.apiIntegration.passed++;
                testResults.apiIntegration.tests.push(`✅ ${service} service is healthy in API`);
            } else {
                testResults.apiIntegration.failed++;
                testResults.apiIntegration.tests.push(`❌ ${service} service is not healthy in API`);
                allHealthy = false;
            }
        });
        
        if (allHealthy) {
            testResults.apiIntegration.passed++;
            testResults.apiIntegration.tests.push('✅ All services healthy in API response');
        }
        
    } catch (error) {
        testResults.apiIntegration.failed++;
        testResults.apiIntegration.tests.push(`❌ API integration test failed: ${error.message}`);
    }
}

/**
 * Test health status UI elements
 */
async function testHealthStatusUI() {
    console.log('\n🏥 Testing Health Status UI Elements...');
    
    try {
        const response = await makeRequest(DASHBOARD_URL);
        
        if (!response.data) {
            testResults.healthStatusUI.failed++;
            testResults.healthStatusUI.tests.push('❌ No page data available for UI testing');
            return;
        }
        
        // Check if health status elements exist in HTML
        const services = ['s3', 'cloudfront', 'lambda', 'route53', 'website'];
        
        services.forEach(service => {
            const statusId = `id="${service}-status"`;
            if (response.data.includes(statusId)) {
                testResults.healthStatusUI.passed++;
                testResults.healthStatusUI.tests.push(`✅ ${service}-status element exists in HTML`);
            } else {
                testResults.healthStatusUI.failed++;
                testResults.healthStatusUI.tests.push(`❌ ${service}-status element missing from HTML`);
            }
        });
        
        // Check if health cards exist
        services.forEach(service => {
            const cardId = `id="${service}-health"`;
            if (response.data.includes(cardId)) {
                testResults.healthStatusUI.passed++;
                testResults.healthStatusUI.tests.push(`✅ ${service}-health card exists in HTML`);
            } else {
                testResults.healthStatusUI.failed++;
                testResults.healthStatusUI.tests.push(`❌ ${service}-health card missing from HTML`);
            }
        });
        
    } catch (error) {
        testResults.healthStatusUI.failed++;
        testResults.healthStatusUI.tests.push(`❌ Health status UI test failed: ${error.message}`);
    }
}

/**
 * Print test results
 */
function printResults() {
    console.log('\n📋 DASHBOARD UI TEST RESULTS');
    console.log('============================');
    
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
    
    console.log(`\n🎯 OVERALL UI TEST: ${totalPassed}/${totalTests} tests passed (${overallPercentage}%)`);
    
    if (overallPercentage >= 90) {
        console.log('✅ Dashboard UI validation PASSED!');
        process.exit(0);
    } else {
        console.log('❌ Dashboard UI validation FAILED!');
        process.exit(1);
    }
}

/**
 * Main test execution
 */
async function runTests() {
    console.log('🚀 Starting Dashboard UI Validation Tests...');
    
    try {
        await testPageAccessibility();
        await testScriptLoading();
        await testApiIntegration();
        await testHealthStatusUI();
        printResults();
    } catch (error) {
        console.error('❌ UI test execution failed:', error.message);
        process.exit(1);
    }
}

// Run tests
runTests();
