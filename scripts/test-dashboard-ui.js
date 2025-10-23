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
const testResults = {
  pageAccessibility: {passed: 0, failed: 0, tests: []},
  scriptLoading: {passed: 0, failed: 0, tests: []},
  apiIntegration: {passed: 0, failed: 0, tests: []},
  healthStatusUI: {passed: 0, failed: 0, tests: []}
};

/**
 * Make HTTP request
 */
function makeRequest(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => resolve({status: res.statusCode, data}));
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

    // Check if page contains expected elements (no service health section)
    if (response.data.includes('System Status')) {
      testResults.pageAccessibility.passed++;
      testResults.pageAccessibility.tests.push('✅ System Status section present');
    } else {
      testResults.pageAccessibility.failed++;
      testResults.pageAccessibility.tests.push('❌ System Status section missing');
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

    // Check if script contains expected functions (health functions removed)
    if (response.data.includes('loadStatusData')) {
      testResults.scriptLoading.passed++;
      testResults.scriptLoading.tests.push('✅ loadStatusData function present');
    } else {
      testResults.scriptLoading.failed++;
      testResults.scriptLoading.tests.push('❌ loadStatusData function missing');
    }

    if (response.data.includes('loadCostData')) {
      testResults.scriptLoading.passed++;
      testResults.scriptLoading.tests.push('✅ loadCostData function present');
    } else {
      testResults.scriptLoading.failed++;
      testResults.scriptLoading.tests.push('❌ loadCostData function missing');
    }

    // Verify health functions are removed
    if (!response.data.includes('loadHealthData') && !response.data.includes('updateHealthStatus')) {
      testResults.scriptLoading.passed++;
      testResults.scriptLoading.tests.push('✅ Health functions successfully removed');
    } else {
      testResults.scriptLoading.failed++;
      testResults.scriptLoading.tests.push('❌ Health functions still present');
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
 * Test system status UI elements (replaces health status)
 */
async function testSystemStatusUI() {
  console.log('\n🏥 Testing System Status UI Elements...');

  try {
    const response = await makeRequest(DASHBOARD_URL);

    if (!response.data) {
      testResults.healthStatusUI.failed++;
      testResults.healthStatusUI.tests.push('❌ No page data available for UI testing');
      return;
    }

    // Check if system status elements exist in HTML
    const statusElements = ['website-status', 'security-status', 'infrastructure-status', 'performance-status'];

    statusElements.forEach(element => {
      const elementId = `id="${element}"`;
      if (response.data.includes(elementId)) {
        testResults.healthStatusUI.passed++;
        testResults.healthStatusUI.tests.push(`✅ ${element} element exists in HTML`);
      } else {
        testResults.healthStatusUI.failed++;
        testResults.healthStatusUI.tests.push(`❌ ${element} element missing from HTML`);
      }
    });

    // Verify service health section is removed
    if (!response.data.includes('Service Health') && !response.data.includes('service-health')) {
      testResults.healthStatusUI.passed++;
      testResults.healthStatusUI.tests.push('✅ Service Health section successfully removed');
    } else {
      testResults.healthStatusUI.failed++;
      testResults.healthStatusUI.tests.push('❌ Service Health section still present');
    }

  } catch (error) {
    testResults.healthStatusUI.failed++;
    testResults.healthStatusUI.tests.push(`❌ System status UI test failed: ${error.message}`);
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
    await testSystemStatusUI();
    printResults();
  } catch (error) {
    console.error('❌ UI test execution failed:', error.message);
    process.exit(1);
  }
}

// Run tests
runTests();
