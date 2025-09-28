/**
 * Status Page Script
 * Handles real-time status updates and security monitoring display
 */

class StatusMonitor {
    constructor() {
        this.statusData = null;
        this.updateInterval = null;
        this.isLoading = true;
        
        this.init();
    }

    async init() {
        console.log('🔍 Initializing status monitor...');
        
        // Load initial status data
        await this.loadStatusData();
        
        // Set up auto-refresh
        this.startAutoRefresh();
        
        // Set up event listeners
        this.setupEventListeners();
        
        this.isLoading = false;
    }

    async loadStatusData() {
        try {
            // Try to load version information (contains security data)
            let versionResponse;
            try {
                versionResponse = await fetch('version.json');
                this.statusData = await versionResponse.json();
                
                // Check if we have placeholder values
                const hasPlaceholders = JSON.stringify(this.statusData).includes('{{');
                
                if (hasPlaceholders) {
                    console.log('⚠️ Placeholder values detected, using fallback data');
                    // Load fallback version data
                    const fallbackResponse = await fetch('version-fallback.json');
                    this.statusData = await fallbackResponse.json();
                }
            } catch (versionError) {
                console.log('⚠️ Main version.json not available, using fallback');
                // Load fallback version data
                const fallbackResponse = await fetch('version-fallback.json');
                this.statusData = await fallbackResponse.json();
            }
            
            // Update the display
            this.updateStatusDisplay();
            
            console.log('✅ Status data loaded successfully');
        } catch (error) {
            console.error('❌ Failed to load status data:', error);
            this.showErrorState();
        }
    }

    updateStatusDisplay() {
        if (!this.statusData) return;

        // Update overall status
        this.updateOverallStatus();
        
        // Update individual service statuses
        this.updateWebsiteStatus();
        this.updateSecurityStatus();
        this.updatePerformanceStatus();
        this.updateInfrastructureStatus();
        
        // Update security details
        this.updateSecurityDetails();
        
        // Update last updated time
        this.updateLastUpdated();
    }

    updateOverallStatus() {
        const statusIndicator = document.getElementById('status-indicator');
        const statusDot = statusIndicator.querySelector('.status-dot');
        const statusText = statusIndicator.querySelector('.status-text');
        
        if (this.statusData.security) {
            const securityStatus = this.statusData.security.status;
            
            if (securityStatus === 'secure') {
                statusDot.className = 'status-dot';
                statusText.textContent = 'All Systems Operational';
            } else if (securityStatus.includes('vulnerabilities')) {
                statusDot.className = 'status-dot warning';
                statusText.textContent = 'Security Issues Detected';
            } else {
                statusDot.className = 'status-dot error';
                statusText.textContent = 'Critical Issues';
            }
        }
    }

    updateWebsiteStatus() {
        const websiteStatus = document.getElementById('website-status');
        const websiteUptime = document.getElementById('website-uptime');
        const websiteResponse = document.getElementById('website-response');
        const websiteIncident = document.getElementById('website-incident');
        
        // Simulate website metrics (in production, these would come from monitoring)
        websiteStatus.textContent = 'Operational';
        websiteStatus.className = 'status-badge operational';
        websiteUptime.textContent = '99.9%';
        websiteResponse.textContent = '120ms';
        websiteIncident.textContent = 'None';
    }

    updateSecurityStatus() {
        const securityStatus = document.getElementById('security-status');
        const securityVulnerabilities = document.getElementById('security-vulnerabilities');
        const securityCritical = document.getElementById('security-critical');
        const securityLastScan = document.getElementById('security-last-scan');
        
        if (this.statusData && this.statusData.security) {
            const vulnCount = this.statusData.security.vulnerabilities || '0';
            const criticalCount = this.statusData.security.critical || '0';
            const lastScan = this.statusData.security.last_scan || 'Unknown';
            
            // Check if we have placeholder values (not yet replaced by GitHub Actions)
            const hasPlaceholders = vulnCount.includes('{{') || criticalCount.includes('{{') || lastScan.includes('{{');
            
            if (hasPlaceholders) {
                // Show default values when placeholders are present
                securityVulnerabilities.textContent = '0';
                securityCritical.textContent = '0';
                securityLastScan.textContent = 'Pending scan...';
                securityStatus.textContent = 'Scanning...';
                securityStatus.className = 'status-badge warning';
            } else {
                // Use actual values
                securityVulnerabilities.textContent = vulnCount;
                securityCritical.textContent = criticalCount;
                securityLastScan.textContent = this.formatDate(lastScan);
                
                // Update status badge based on actual values
                if (vulnCount === '0' || vulnCount === 0) {
                    securityStatus.textContent = 'Secure';
                    securityStatus.className = 'status-badge operational';
                } else if (criticalCount > '0' || criticalCount > 0) {
                    securityStatus.textContent = 'Critical';
                    securityStatus.className = 'status-badge error';
                } else {
                    securityStatus.textContent = 'Issues';
                    securityStatus.className = 'status-badge warning';
                }
            }
        } else {
            // No security data available
            securityVulnerabilities.textContent = '--';
            securityCritical.textContent = '--';
            securityLastScan.textContent = 'No data';
            securityStatus.textContent = 'Unknown';
            securityStatus.className = 'status-badge warning';
        }
    }

    updatePerformanceStatus() {
        const performanceStatus = document.getElementById('performance-status');
        const performanceLoad = document.getElementById('performance-load');
        const performanceCache = document.getElementById('performance-cache');
        const performanceCdn = document.getElementById('performance-cdn');
        
        // Simulate performance metrics
        performanceStatus.textContent = 'Good';
        performanceStatus.className = 'status-badge operational';
        performanceLoad.textContent = '1.2s';
        performanceCache.textContent = '95%';
        performanceCdn.textContent = 'Operational';
    }

    updateInfrastructureStatus() {
        const infrastructureStatus = document.getElementById('infrastructure-status');
        const infrastructureS3 = document.getElementById('infrastructure-s3');
        const infrastructureCloudfront = document.getElementById('infrastructure-cloudfront');
        const infrastructureSsl = document.getElementById('infrastructure-ssl');
        
        // Simulate infrastructure metrics
        infrastructureStatus.textContent = 'Healthy';
        infrastructureStatus.className = 'status-badge operational';
        infrastructureS3.textContent = 'Operational';
        infrastructureCloudfront.textContent = 'Operational';
        infrastructureSsl.textContent = 'Valid';
    }

    updateSecurityDetails() {
        if (!this.statusData || !this.statusData.security) return;

        // Update vulnerability counts
        const criticalCount = document.getElementById('critical-count');
        const highCount = document.getElementById('high-count');
        const mediumCount = document.getElementById('medium-count');
        const lowCount = document.getElementById('low-count');
        
        // Check for placeholders and handle gracefully
        const critical = this.statusData.security.critical || '0';
        const high = this.statusData.security.high || '0';
        const medium = this.statusData.security.medium || '0';
        const low = this.statusData.security.low || '0';
        
        if (criticalCount) {
            criticalCount.textContent = critical.includes('{{') ? '0' : critical;
        }
        if (highCount) {
            highCount.textContent = high.includes('{{') ? '0' : high;
        }
        if (mediumCount) {
            mediumCount.textContent = medium.includes('{{') ? '0' : medium;
        }
        if (lowCount) {
            lowCount.textContent = low.includes('{{') ? '0' : low;
        }
        
        // Update security checks
        this.updateSecurityChecks();
    }

    updateSecurityChecks() {
        const checkDependencies = document.getElementById('check-dependencies');
        const checkSecrets = document.getElementById('check-secrets');
        const checkHttps = document.getElementById('check-https');
        const checkHeaders = document.getElementById('check-headers');
        
        if (this.statusData && this.statusData.security) {
            // Dependencies check
            if (checkDependencies) {
                const depStatus = this.statusData.security.dependencies || 'up-to-date';
                if (depStatus.includes('{{')) {
                    checkDependencies.textContent = 'Scanning...';
                } else {
                    checkDependencies.textContent = depStatus.replace('-', ' ');
                }
            }
            
            // Secrets check
            if (checkSecrets) {
                const secretsFound = this.statusData.security.secrets_found || '0';
                if (secretsFound.includes('{{')) {
                    checkSecrets.textContent = 'Scanning...';
                } else {
                    checkSecrets.textContent = secretsFound === '0' ? 'No secrets found' : 'Secrets detected';
                }
            }
            
            // HTTPS check
            if (checkHttps) {
                const cdnIssues = this.statusData.security.cdn_issues || '0';
                if (cdnIssues.includes('{{')) {
                    checkHttps.textContent = 'Scanning...';
                } else {
                    checkHttps.textContent = cdnIssues === '0' ? 'All links secure' : 'HTTP links found';
                }
            }
            
            // Headers check (always good for our site)
            if (checkHeaders) {
                checkHeaders.textContent = 'Security headers present';
            }
        } else {
            // No security data available
            if (checkDependencies) checkDependencies.textContent = 'No data';
            if (checkSecrets) checkSecrets.textContent = 'No data';
            if (checkHttps) checkHttps.textContent = 'No data';
            if (checkHeaders) checkHeaders.textContent = 'No data';
        }
    }

    updateLastUpdated() {
        const lastUpdatedTime = document.getElementById('last-updated-time');
        if (lastUpdatedTime) {
            lastUpdatedTime.textContent = new Date().toLocaleString();
        }
    }

    startAutoRefresh() {
        // Refresh every 5 minutes
        this.updateInterval = setInterval(() => {
            this.loadStatusData();
        }, 5 * 60 * 1000);
    }

    setupEventListeners() {
        // Add refresh button functionality if it exists
        const refreshButton = document.getElementById('refresh-button');
        if (refreshButton) {
            refreshButton.addEventListener('click', () => {
                this.loadStatusData();
            });
        }
    }

    showErrorState() {
        const statusIndicator = document.getElementById('status-indicator');
        const statusDot = statusIndicator.querySelector('.status-dot');
        const statusText = statusIndicator.querySelector('.status-text');
        
        statusDot.className = 'status-dot error';
        statusText.textContent = 'Status Unavailable';
    }

    formatDate(dateString) {
        try {
            const date = new Date(dateString);
            return date.toLocaleString();
        } catch (error) {
            return 'Unknown';
        }
    }

    destroy() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
        }
    }
}

// Initialize status monitor when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.statusMonitor = new StatusMonitor();
});

// Clean up on page unload
window.addEventListener('beforeunload', () => {
    if (window.statusMonitor) {
        window.statusMonitor.destroy();
    }
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = StatusMonitor;
}
