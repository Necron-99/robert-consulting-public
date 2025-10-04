/**
 * AWS Monitoring Dashboard Script
 * Handles real-time data updates and interactive functionality
 */

class MonitoringDashboard {
    constructor() {
        this.refreshInterval = null;
        this.isLoading = false;
        this.lastUpdate = null;
        
        this.init();
    }

    /**
     * Initialize the monitoring dashboard
     */
    init() {
        console.log('🚀 Initializing AWS Monitoring Dashboard...');
        
        // Bind event listeners
        this.bindEventListeners();
        
        // Load initial data
        this.loadInitialData();
        
        // Set up auto-refresh
        this.setupAutoRefresh();
        
        console.log('✅ Monitoring Dashboard initialized');
    }

    /**
     * Bind event listeners
     */
    bindEventListeners() {
        // Refresh buttons
        const refreshButtons = document.querySelectorAll('[id^="refresh-"]');
        refreshButtons.forEach(button => {
            button.addEventListener('click', (e) => {
                const section = e.target.id.replace('refresh-', '');
                this.refreshSection(section);
            });
        });

        // Global refresh
        const globalRefresh = document.getElementById('global-refresh');
        if (globalRefresh) {
            globalRefresh.addEventListener('click', () => {
                this.refreshAllSections();
            });
        }
    }

    /**
     * Load initial data
     */
    async loadInitialData() {
        console.log('📊 Loading initial monitoring data...');
        
        try {
            await Promise.all([
                this.loadCostData(),
                this.loadHealthData(),
                this.loadPerformanceData()
            ]);
            
            this.updateLastUpdated();
            console.log('✅ Initial data loaded successfully');
        } catch (error) {
            console.error('❌ Failed to load initial data:', error);
            this.showError('Failed to load monitoring data');
        }
    }

    /**
     * Load cost monitoring data
     */
    async loadCostData() {
        // Simulate API call - replace with actual AWS Cost Explorer API
        const costData = {
            totalMonthly: 45.67,
            s3Cost: 12.34,
            cloudfrontCost: 8.90,
            lambdaCost: 2.45,
            route53Cost: 0.50,
            sesCost: 0.00,
            otherCost: 21.48,
            trend: '+5.2%'
        };

        // Update cost displays
        this.updateElement('total-cost', `$${costData.totalMonthly.toFixed(2)}`);
        this.updateElement('total-monthly-cost', `$${costData.totalMonthly.toFixed(2)}`);
        this.updateElement('cost-trend', costData.trend);
        
        this.updateElement('s3-cost', `$${costData.s3Cost.toFixed(2)}`);
        this.updateElement('s3-storage', '2.5 GB');
        this.updateElement('s3-objects', '1,234');
        
        this.updateElement('cloudfront-cost', `$${costData.cloudfrontCost.toFixed(2)}`);
        this.updateElement('cloudfront-requests', '45,678');
        this.updateElement('cloudfront-bandwidth', '2.1 GB');
        
        this.updateElement('lambda-cost', `$${costData.lambdaCost.toFixed(2)}`);
        this.updateElement('lambda-invocations', '1,234');
        this.updateElement('lambda-duration', '2.5s');
        
        this.updateElement('route53-cost', `$${costData.route53Cost.toFixed(2)}`);
        this.updateElement('route53-queries', '5,678');
        this.updateElement('route53-health-checks', '3');
        
        this.updateElement('ses-cost', `$${costData.sesCost.toFixed(2)}`);
        this.updateElement('ses-emails', '0');
        this.updateElement('ses-bounces', '0');
    }

    /**
     * Load health monitoring data
     */
    async loadHealthData() {
        // Simulate health checks - replace with actual AWS health checks
        const healthData = {
            s3: { status: 'healthy', requests: '99.9%', errors: '0.1%' },
            cloudfront: { status: 'healthy', cacheHit: '85%', errors: '0.2%' },
            lambda: { status: 'healthy', invocations: '100%', errors: '0%' },
            route53: { status: 'healthy', resolution: '100%', queries: '5,678' },
            website: { status: 'healthy', http: '200', ssl: 'Valid' },
            route53Health: { status: 'healthy', resolution: '100%', queries: '5,678', healthChecks: '3' }
        };

        // Update health displays
        this.updateHealthStatus('s3-health', healthData.s3);
        this.updateHealthStatus('cloudfront-health', healthData.cloudfront);
        this.updateHealthStatus('lambda-health', healthData.lambda);
        this.updateHealthStatus('route53-health', healthData.route53);
        this.updateHealthStatus('website-health', healthData.website);
        this.updateHealthStatus('route53-health', healthData.route53Health);
    }

    /**
     * Load performance monitoring data
     */
    async loadPerformanceData() {
        // Simulate performance metrics - replace with actual performance data
        const performanceData = {
            coreWebVitals: {
                lcp: { value: '1.2s', score: 'good' },
                fid: { value: '45ms', score: 'good' },
                cls: { value: '0.05', score: 'good' }
            },
            pageSpeed: {
                mobile: { score: 95, grade: 'A' },
                desktop: { score: 98, grade: 'A' }
            },
            resourceTiming: {
                dns: '12ms',
                connect: '45ms',
                ssl: '23ms',
                ttfb: '180ms',
                dom: '320ms',
                load: '1.2s'
            }
        };

        // Update performance displays
        this.updatePerformanceMetrics('core-web-vitals', performanceData.coreWebVitals);
        this.updatePerformanceMetrics('page-speed', performanceData.pageSpeed);
        this.updatePerformanceMetrics('resource-timing', performanceData.resourceTiming);
    }

    /**
     * Update health status display
     */
    updateHealthStatus(elementId, data) {
        const element = document.getElementById(elementId);
        if (!element) return;

        const statusElement = element.querySelector('.health-status');
        const metrics = element.querySelectorAll('.metric-value');

        if (statusElement) {
            statusElement.textContent = data.status;
            statusElement.className = `health-status ${data.status}`;
        }

        // Update metrics based on available data
        if (data.requests) this.updateElement(`${elementId}-requests`, data.requests);
        if (data.errors) this.updateElement(`${elementId}-errors`, data.errors);
        if (data.cacheHit) this.updateElement(`${elementId}-cache-hit`, data.cacheHit);
        if (data.invocations) this.updateElement(`${elementId}-invocations`, data.invocations);
        if (data.resolution) this.updateElement(`${elementId}-resolution`, data.resolution);
        if (data.queries) this.updateElement(`${elementId}-queries`, data.queries);
        if (data.healthChecks) this.updateElement(`${elementId}-health-checks`, data.healthChecks);
        if (data.http) this.updateElement(`${elementId}-http-status`, data.http);
        if (data.ssl) this.updateElement(`${elementId}-ssl-status`, data.ssl);
    }

    /**
     * Update performance metrics display
     */
    updatePerformanceMetrics(elementId, data) {
        const element = document.getElementById(elementId);
        if (!element) return;

        if (data.lcp) {
            this.updateElement(`${elementId}-lcp`, data.lcp.value);
            this.updateElement(`${elementId}-lcp-score`, data.lcp.score);
        }
        if (data.fid) {
            this.updateElement(`${elementId}-fid`, data.fid.value);
            this.updateElement(`${elementId}-fid-score`, data.fid.score);
        }
        if (data.cls) {
            this.updateElement(`${elementId}-cls`, data.cls.value);
            this.updateElement(`${elementId}-cls-score`, data.cls.score);
        }
        if (data.mobile) {
            this.updateElement(`${elementId}-mobile-score`, data.mobile.score);
            this.updateElement(`${elementId}-mobile-grade`, data.mobile.grade);
        }
        if (data.desktop) {
            this.updateElement(`${elementId}-desktop-score`, data.desktop.score);
            this.updateElement(`${elementId}-desktop-grade`, data.desktop.grade);
        }
        if (data.dns) this.updateElement(`${elementId}-dns`, data.dns);
        if (data.connect) this.updateElement(`${elementId}-connect`, data.connect);
        if (data.ssl) this.updateElement(`${elementId}-ssl`, data.ssl);
        if (data.ttfb) this.updateElement(`${elementId}-ttfb`, data.ttfb);
        if (data.dom) this.updateElement(`${elementId}-dom`, data.dom);
        if (data.load) this.updateElement(`${elementId}-load`, data.load);
    }

    /**
     * Update a single element
     */
    updateElement(id, value) {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = value;
        }
    }

    /**
     * Refresh a specific section
     */
    async refreshSection(section) {
        if (this.isLoading) return;

        console.log(`🔄 Refreshing ${section} section...`);
        this.setLoading(true);

        try {
            switch (section) {
                case 'costs':
                    await this.loadCostData();
                    break;
                case 'health':
                    await this.loadHealthData();
                    break;
                case 'performance':
                    await this.loadPerformanceData();
                    break;
                default:
                    await this.loadInitialData();
            }
            
            this.updateLastUpdated();
            console.log(`✅ ${section} section refreshed`);
        } catch (error) {
            console.error(`❌ Failed to refresh ${section}:`, error);
            this.showError(`Failed to refresh ${section} data`);
        } finally {
            this.setLoading(false);
        }
    }

    /**
     * Refresh all sections
     */
    async refreshAllSections() {
        console.log('🔄 Refreshing all sections...');
        await this.loadInitialData();
    }

    /**
     * Set loading state
     */
    setLoading(loading) {
        this.isLoading = loading;
        const refreshButtons = document.querySelectorAll('[id^="refresh-"]');
        refreshButtons.forEach(button => {
            button.disabled = loading;
            if (loading) {
                button.textContent = 'Refreshing...';
            } else {
                button.textContent = 'Refresh';
            }
        });
    }

    /**
     * Update last updated timestamp
     */
    updateLastUpdated() {
        this.lastUpdate = new Date();
        const lastUpdatedElements = document.querySelectorAll('.last-updated');
        lastUpdatedElements.forEach(element => {
            element.textContent = `Last updated: ${this.lastUpdate.toLocaleTimeString()}`;
        });
    }

    /**
     * Setup auto-refresh
     */
    setupAutoRefresh() {
        // Auto-refresh every 5 minutes
        this.refreshInterval = setInterval(() => {
            if (!this.isLoading) {
                this.refreshAllSections();
            }
        }, 5 * 60 * 1000);
    }

    /**
     * Show error message
     */
    showError(message) {
        console.error('❌ Error:', message);
        // You could add a toast notification or error display here
    }

    /**
     * Cleanup
     */
    destroy() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.monitoringDashboard = new MonitoringDashboard();
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (window.monitoringDashboard) {
        window.monitoringDashboard.destroy();
    }
});