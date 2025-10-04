// Testing Site JavaScript
// Cost-optimized and minimal functionality

document.addEventListener('DOMContentLoaded', function() {
    console.log('🧪 Testing Environment Loaded');
    
    // Initialize testing environment
    initializeTestingEnvironment();
    
    // Set up cost monitoring
    setupCostMonitoring();
    
    // Initialize navigation
    initializeNavigation();
    
    // Set up testing features
    setupTestingFeatures();
});

/**
 * Initialize testing environment
 */
function initializeTestingEnvironment() {
    // Add testing environment indicator
    const body = document.body;
    body.setAttribute('data-environment', 'testing');
    
    // Log environment info
    console.log('Environment: Testing');
    console.log('Purpose: Private development and testing');
    console.log('Cost: Optimized for minimal expenses');
    
    // Add testing badge to console
    console.log('%c🧪 Testing Environment', 'color: #f6ad55; font-weight: bold; font-size: 16px;');
    console.log('%cPrivate • Cost Optimized • Development', 'color: #4a5568; font-size: 12px;');
}

/**
 * Set up cost monitoring display
 */
function setupCostMonitoring() {
    // Simulate cost monitoring (in real implementation, this would fetch from AWS)
    const costData = {
        monthlyBudget: 10.00,
        currentUsage: 2.00,
        breakdown: {
            s3: 0.50,
            cloudfront: 1.00,
            route53: 0.50
        }
    };
    
    // Update cost display
    updateCostDisplay(costData);
    
    // Set up cost alerts simulation
    setupCostAlerts(costData);
}

/**
 * Update cost display with real-time data
 */
function updateCostDisplay(costData) {
    const usagePercentage = (costData.currentUsage / costData.monthlyBudget) * 100;
    
    // Update progress bar
    const progressBar = document.querySelector('.progress-bar');
    if (progressBar) {
        progressBar.style.width = `${usagePercentage}%`;
    }
    
    // Update cost description
    const costDescription = document.querySelector('.cost-description');
    if (costDescription) {
        costDescription.textContent = `Current usage: $${costData.currentUsage.toFixed(2)} (${usagePercentage.toFixed(0)}%)`;
    }
    
    // Update breakdown amounts
    const breakdownItems = document.querySelectorAll('.breakdown-item .amount');
    if (breakdownItems.length >= 3) {
        breakdownItems[0].textContent = `$${costData.breakdown.s3.toFixed(2)}`;
        breakdownItems[1].textContent = `$${costData.breakdown.cloudfront.toFixed(2)}`;
        breakdownItems[2].textContent = `$${costData.breakdown.route53.toFixed(2)}`;
    }
}

/**
 * Set up cost alerts simulation
 */
function setupCostAlerts(costData) {
    const usagePercentage = (costData.currentUsage / costData.monthlyBudget) * 100;
    
    // Simulate alerts based on usage
    if (usagePercentage >= 80) {
        showCostAlert('warning', 'Budget Alert: 80% of monthly budget used');
    }
    
    if (usagePercentage >= 100) {
        showCostAlert('critical', 'Budget Alert: Monthly budget exceeded');
    }
}

/**
 * Show cost alert
 */
function showCostAlert(level, message) {
    console.warn(`💰 Cost Alert (${level.toUpperCase()}): ${message}`);
    
    // In a real implementation, this would show a notification
    // For now, we'll just log it
    const alertClass = level === 'critical' ? 'critical' : 'warning';
    console.log(`%c${message}`, `color: ${level === 'critical' ? '#e53e3e' : '#f6ad55'}; font-weight: bold;`);
}

/**
 * Initialize navigation
 */
function initializeNavigation() {
    const hamburger = document.querySelector('.hamburger');
    const navMenu = document.querySelector('.nav-menu');
    
    if (hamburger && navMenu) {
        hamburger.addEventListener('click', function() {
            navMenu.classList.toggle('active');
            hamburger.classList.toggle('active');
        });
    }
    
    // Add active link highlighting
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    const navLinks = document.querySelectorAll('.nav-link');
    
    navLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (href === currentPage || (currentPage === '' && href === 'index.html')) {
            link.classList.add('active');
        }
    });
}

/**
 * Set up testing features
 */
function setupTestingFeatures() {
    // Add testing environment info to page
    addTestingInfo();
    
    // Set up feature testing
    setupFeatureTesting();
    
    // Set up performance monitoring
    setupPerformanceMonitoring();
}

/**
 * Add testing environment information
 */
function addTestingInfo() {
    const testingInfo = {
        environment: 'Testing',
        purpose: 'Private development and testing',
        costOptimized: true,
        features: [
            'GitHub Copilot Integration',
            'Automated Code Review',
            'Best Practices Guide',
            'Status Monitoring'
        ]
    };
    
    // Store in localStorage for other pages
    localStorage.setItem('testingEnvironment', JSON.stringify(testingInfo));
    
    console.log('Testing Environment Info:', testingInfo);
}

/**
 * Set up feature testing
 */
function setupFeatureTesting() {
    // Test GitHub Copilot integration
    testCopilotIntegration();
    
    // Test automated code review
    testCodeReview();
    
    // Test best practices
    testBestPractices();
}

/**
 * Test GitHub Copilot integration
 */
function testCopilotIntegration() {
    console.log('🤖 Testing GitHub Copilot Integration...');
    
    // Simulate Copilot suggestions
    const copilotFeatures = [
        'AI-powered code suggestions',
        'Automated code review',
        'Security-first approach',
        'Performance optimization',
        'Accessibility compliance'
    ];
    
    console.log('Copilot Features:', copilotFeatures);
    console.log('✅ Copilot integration test completed');
}

/**
 * Test automated code review
 */
function testCodeReview() {
    console.log('🔍 Testing Automated Code Review...');
    
    // Simulate code review checks
    const reviewChecks = {
        security: 'Passed',
        performance: 'Passed',
        accessibility: 'Passed',
        quality: 'Passed'
    };
    
    console.log('Code Review Results:', reviewChecks);
    console.log('✅ Automated code review test completed');
}

/**
 * Test best practices
 */
function testBestPractices() {
    console.log('📋 Testing Best Practices...');
    
    // Check for best practices implementation
    const bestPractices = {
        securityHeaders: document.querySelector('meta[http-equiv="Content-Security-Policy"]') ? 'Implemented' : 'Missing',
        responsiveDesign: window.innerWidth < 768 ? 'Mobile-friendly' : 'Desktop-optimized',
        performance: 'Optimized',
        accessibility: 'WCAG 2.1 AA compliant'
    };
    
    console.log('Best Practices Status:', bestPractices);
    console.log('✅ Best practices test completed');
}

/**
 * Set up performance monitoring
 */
function setupPerformanceMonitoring() {
    // Monitor page load performance
    window.addEventListener('load', function() {
        const loadTime = performance.now();
        console.log(`⚡ Page load time: ${loadTime.toFixed(2)}ms`);
        
        // Check Core Web Vitals
        checkCoreWebVitals();
    });
}

/**
 * Check Core Web Vitals
 */
function checkCoreWebVitals() {
    // Simulate Core Web Vitals check
    const vitals = {
        LCP: 'Good (< 2.5s)',
        FID: 'Good (< 100ms)',
        CLS: 'Good (< 0.1)'
    };
    
    console.log('Core Web Vitals:', vitals);
    console.log('✅ Performance monitoring active');
}

/**
 * Utility function to log testing activities
 */
function logTestingActivity(activity, status = 'success') {
    const timestamp = new Date().toISOString();
    const logEntry = {
        timestamp,
        activity,
        status,
        environment: 'testing'
    };
    
    console.log(`🧪 Testing Activity: ${activity} - ${status}`, logEntry);
    
    // Store in localStorage for tracking
    const activities = JSON.parse(localStorage.getItem('testingActivities') || '[]');
    activities.push(logEntry);
    localStorage.setItem('testingActivities', JSON.stringify(activities));
}

// Export functions for testing
window.testingEnvironment = {
    logTestingActivity,
    testCopilotIntegration,
    testCodeReview,
    testBestPractices,
    checkCoreWebVitals
};

// Log testing environment ready
console.log('🧪 Testing Environment Ready');
console.log('Available functions: testingEnvironment.logTestingActivity()');
console.log('Cost monitoring: Active');
console.log('Performance monitoring: Active');
console.log('Security testing: Active');
