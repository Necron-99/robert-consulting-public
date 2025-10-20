/**
 * CloudWatch Synthetics Performance Monitor
 * Tests performance from AWS edge locations (network-independent)
 */

const synthetics = require('Synthetics');
const log = require('SyntheticsLogger');

async function loadBlueprint() {
    // Set configuration options for our script
    // Note: requestOptions variables removed as they were unused

    // Set up the page
    const page = await synthetics.getPage();
    
    // Test production site
    await testSitePerformance(page, 'https://robertconsulting.net/dashboard.html', 'Production');
    
    // Test staging site
    await testSitePerformance(page, 'https://d3guz3lq4sqlvl.cloudfront.net/?secret=<staging-secret>', 'Staging');
}

async function testSitePerformance(page, url, environment) {
    log.info(`Testing ${environment} site performance: ${url}`);
    
    // Navigate to the page
    await page.goto(url, {waitUntil: 'networkidle0', timeout: 30000});
    
    // Wait for page to be fully loaded
    await page.waitForTimeout(2000);
    
    // Get performance metrics
    const performanceMetrics = await page.evaluate(() => {
        return new Promise((resolve) => {
            // Wait for performance metrics to be available
            setTimeout(() => {
                const navigation = performance.getEntriesByType('navigation')[0];
                const paint = performance.getEntriesByType('paint');
                
                // Calculate Core Web Vitals
                const lcp = performance.getEntriesByType('largest-contentful-paint');
                const cls = performance.getEntriesByType('layout-shift');
                
                // Calculate CLS
                let clsValue = 0;
                cls.forEach(entry => {
                    if (!entry.hadRecentInput) {
                        clsValue += entry.value;
                    }
                });
                
                resolve({
                    // Navigation timing
                    ttfb: navigation ? Math.round(navigation.responseStart - navigation.requestStart) : 0,
                    domContentLoaded: navigation ? Math.round(navigation.domContentLoadedEventEnd - navigation.navigationStart) : 0,
                    loadComplete: navigation ? Math.round(navigation.loadEventEnd - navigation.navigationStart) : 0,
                    
                    // Paint timing
                    firstPaint: paint.find(p => p.name === 'first-paint') ? Math.round(paint.find(p => p.name === 'first-paint').startTime) : 0,
                    firstContentfulPaint: paint.find(p => p.name === 'first-contentful-paint') ? Math.round(paint.find(p => p.name === 'first-contentful-paint').startTime) : 0,
                    
                    // Core Web Vitals
                    lcp: lcp.length > 0 ? Math.round(lcp[lcp.length - 1].startTime) : 0,
                    cls: Math.round(clsValue * 1000) / 1000, // Round to 3 decimal places
                    
                    // Resource timing
                    resourceCount: performance.getEntriesByType('resource').length,
                    totalSize: performance.getEntriesByType('resource').reduce((total, resource) => {
                        return total + (resource.transferSize || 0);
                    }, 0)
                });
            }, 1000);
        });
    });
    
    // Log performance metrics
    log.info(`${environment} Performance Metrics:`, JSON.stringify(performanceMetrics, null, 2));
    
    // Validate performance thresholds (excellent site standards)
    const thresholds = {
        ttfb: 200, // 200ms
        lcp: 1800, // 1.8s
        cls: 0.05, // 0.05
        domContentLoaded: 2000, // 2s
        loadComplete: 3000 // 3s
    };
    
    // Check TTFB
    if (performanceMetrics.ttfb > thresholds.ttfb) {
        throw new Error(`${environment} TTFB too high: ${performanceMetrics.ttfb}ms (threshold: ${thresholds.ttfb}ms)`);
    }
    
    // Check LCP
    if (performanceMetrics.lcp > thresholds.lcp) {
        throw new Error(`${environment} LCP too high: ${performanceMetrics.lcp}ms (threshold: ${thresholds.lcp}ms)`);
    }
    
    // Check CLS
    if (performanceMetrics.cls > thresholds.cls) {
        throw new Error(`${environment} CLS too high: ${performanceMetrics.cls} (threshold: ${thresholds.cls})`);
    }
    
    // Check DOM Content Loaded
    if (performanceMetrics.domContentLoaded > thresholds.domContentLoaded) {
        throw new Error(`${environment} DOM Content Loaded too slow: ${performanceMetrics.domContentLoaded}ms (threshold: ${thresholds.domContentLoaded}ms)`);
    }
    
    log.info(`${environment} performance test passed - all thresholds met`);
    
    // Test security headers
    await testSecurityHeaders(page, environment);
}

async function testSecurityHeaders(page, environment) {
    log.info(`Testing ${environment} security headers`);
    
    const response = await page.goto(page.url(), {waitUntil: 'networkidle0'});
    const headers = response.headers();
    
    const requiredHeaders = [
        'strict-transport-security',
        'x-content-type-options',
        'x-frame-options',
        'x-xss-protection',
        'referrer-policy',
        'content-security-policy',
        'permissions-policy',
        'cross-origin-embedder-policy'
    ];
    
    const missingHeaders = requiredHeaders.filter(header => !getHeaderValue(headers, header));
    
    if (missingHeaders.length > 0) {
        throw new Error(`${environment} missing security headers: ${missingHeaders.join(', ')}`);
    }
    
    log.info(`${environment} security headers test passed - all 8 headers present`);
}

/**
 * Get header value safely
 */
function getHeaderValue(headers, header) {
    switch (header) {
        case 'strict-transport-security':
            return headers['strict-transport-security'];
        case 'x-frame-options':
            return headers['x-frame-options'];
        case 'x-content-type-options':
            return headers['x-content-type-options'];
        case 'referrer-policy':
            return headers['referrer-policy'];
        case 'content-security-policy':
            return headers['content-security-policy'];
        case 'permissions-policy':
            return headers['permissions-policy'];
        case 'cross-origin-embedder-policy':
            return headers['cross-origin-embedder-policy'];
        default:
            return undefined;
    }
}

// Export the handler
exports.handler = async() => {
    return await loadBlueprint();
};
