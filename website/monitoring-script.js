// AWS Monitoring Dashboard Script
// Real-time monitoring of AWS costs and service health

class AWSMonitoringDashboard {
    constructor() {
        this.costData = {};
        this.healthData = {};
        this.performanceData = {};
        this.alerts = [];
        this.refreshInterval = 30000; // 30 seconds
        this.isRefreshing = false;
        
        this.init();
    }
    
    init() {
        console.log('🚀 Initializing AWS Monitoring Dashboard...');
        
        // Set up event listeners
        this.setupEventListeners();
        
        // Load initial data
        this.loadCostData();
        this.loadHealthData();
        this.loadPerformanceData();
        
        // Set up auto-refresh
        this.setupAutoRefresh();
        
        // Update last updated time
        this.updateLastUpdated();
        
        console.log('✅ AWS Monitoring Dashboard initialized');
    }
    
    setupEventListeners() {
        // Refresh buttons
        document.getElementById('refresh-costs').addEventListener('click', () => {
            this.loadCostData();
        });
        
        document.getElementById('refresh-health').addEventListener('click', () => {
            this.loadHealthData();
        });
        
        document.getElementById('refresh-performance').addEventListener('click', () => {
            this.loadPerformanceData();
        });
    }
    
    setupAutoRefresh() {
        setInterval(() => {
            if (!this.isRefreshing) {
                this.refreshAllData();
            }
        }, this.refreshInterval);
    }
    
    async refreshAllData() {
        this.isRefreshing = true;
        
        try {
            await Promise.all([
                this.loadCostData(),
                this.loadHealthData(),
                this.loadPerformanceData()
            ]);
            
            this.updateLastUpdated();
        } catch (error) {
            console.error('Error refreshing data:', error);
        } finally {
            this.isRefreshing = false;
        }
    }
    
    async loadCostData() {
        try {
            console.log('💰 Loading cost data...');
            
            // Simulate API call to AWS Cost Explorer
            // In a real implementation, this would call your backend API
            const costData = await this.fetchCostData();
            
            this.costData = costData;
            this.updateCostDisplay();
            this.updateCostAlerts();
            
            console.log('✅ Cost data loaded successfully');
        } catch (error) {
            console.error('❌ Error loading cost data:', error);
            this.showError('Failed to load cost data');
        }
    }
    
    async loadHealthData() {
        try {
            console.log('🏥 Loading health data...');
            
            // Simulate API call to AWS CloudWatch
            const healthData = await this.fetchHealthData();
            
            this.healthData = healthData;
            this.updateHealthDisplay();
            
            console.log('✅ Health data loaded successfully');
        } catch (error) {
            console.error('❌ Error loading health data:', error);
            this.showError('Failed to load health data');
        }
    }
    
    async loadPerformanceData() {
        try {
            console.log('⚡ Loading performance data...');
            
            // Simulate API call to performance monitoring
            const performanceData = await this.fetchPerformanceData();
            
            this.performanceData = performanceData;
            this.updatePerformanceDisplay();
            
            console.log('✅ Performance data loaded successfully');
        } catch (error) {
            console.error('❌ Error loading performance data:', error);
            this.showError('Failed to load performance data');
        }
    }
    
    async fetchCostData() {
        // Simulate AWS Cost Explorer API call
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({
                    total: 12.45,
                    s3: 3.20,
                    cloudfront: 8.15,
                    route53: 1.10,
                    s3Storage: '2.5 GB',
                    s3Objects: 156,
                    cloudfrontRequests: 12543,
                    cloudfrontData: '45.2 GB',
                    route53Queries: 8923,
                    route53Health: 12
                });
            }, 1000);
        });
    }
    
    async fetchHealthData() {
        // Simulate AWS CloudWatch API call
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({
                    s3: {
                        status: 'healthy',
                        bucketStatus: 'accessible',
                        storageUsed: '2.5 GB',
                        objectCount: 156
                    },
                    cloudfront: {
                        status: 'healthy',
                        distributionStatus: 'deployed',
                        cacheHit: '94.2%',
                        errorRate: '0.1%'
                    },
                    website: {
                        status: 'healthy',
                        responseTime: '245ms',
                        httpStatus: '200',
                        sslStatus: 'valid'
                    },
                    route53: {
                        status: 'healthy',
                        resolution: 'working',
                        queries: 8923,
                        healthChecks: 12
                    }
                });
            }, 1000);
        });
    }
    
    async fetchPerformanceData() {
        // Simulate performance monitoring API call
        return new Promise((resolve) => {
            setTimeout(() => {
                resolve({
                    lcp: 1.2,
                    fid: 45,
                    cls: 0.05,
                    ttfb: 180,
                    fcp: 0.8
                });
            }, 1000);
        });
    }
    
    updateCostDisplay() {
        const data = this.costData;
        
        // Update hero stats
        document.getElementById('total-cost').textContent = `$${data.total.toFixed(2)}`;
        
        // Update cost cards
        document.getElementById('total-monthly-cost').textContent = `$${data.total.toFixed(2)}`;
        document.getElementById('s3-cost').textContent = `$${data.s3.toFixed(2)}`;
        document.getElementById('cloudfront-cost').textContent = `$${data.cloudfront.toFixed(2)}`;
        document.getElementById('route53-cost').textContent = `$${data.route53.toFixed(2)}`;
        
        // Update cost breakdowns
        document.getElementById('s3-storage').textContent = data.s3Storage;
        document.getElementById('s3-objects').textContent = data.s3Objects;
        document.getElementById('cloudfront-requests').textContent = data.cloudfrontRequests.toLocaleString();
        document.getElementById('cloudfront-data').textContent = data.cloudfrontData;
        document.getElementById('route53-queries').textContent = data.route53Queries.toLocaleString();
        document.getElementById('route53-health').textContent = data.route53Health;
        
        // Update cost trend
        const costTrend = document.getElementById('cost-trend');
        const trend = this.calculateCostTrend();
        costTrend.textContent = trend;
        costTrend.className = `cost-trend ${trend.includes('increase') ? 'trend-up' : 'trend-down'}`;
    }
    
    updateHealthDisplay() {
        const data = this.healthData;
        
        // Update service health status
        this.updateServiceStatus('s3', data.s3);
        this.updateServiceStatus('cloudfront', data.cloudfront);
        this.updateServiceStatus('website', data.website);
        this.updateServiceStatus('route53', data.route53);
        
        // Update hero stats
        const healthyServices = Object.values(data).filter(service => service.status === 'healthy').length;
        const totalServices = Object.keys(data).length;
        const healthPercentage = Math.round((healthyServices / totalServices) * 100);
        
        document.getElementById('service-health').textContent = `${healthPercentage}%`;
    }
    
    updateServiceStatus(serviceName, serviceData) {
        const statusElement = document.getElementById(`${serviceName}-status`);
        const cardElement = document.getElementById(`${serviceName}-health`);
        
        // Update status badge
        statusElement.textContent = serviceData.status;
        statusElement.className = `health-status ${serviceData.status}`;
        
        // Update card background
        cardElement.className = `health-card ${serviceData.status}`;
        
        // Update metrics
        Object.keys(serviceData).forEach(key => {
            const element = document.getElementById(`${serviceName}-${key.replace(/([A-Z])/g, '-$1').toLowerCase()}`);
            if (element) {
                element.textContent = serviceData[key];
            }
        });
    }
    
    updatePerformanceDisplay() {
        const data = this.performanceData;
        
        // Update Core Web Vitals
        document.getElementById('lcp').textContent = `${(data.lcp * 1000).toFixed(0)}ms`;
        document.getElementById('fid').textContent = `${data.fid}ms`;
        document.getElementById('cls').textContent = data.cls.toFixed(3);
        
        // Update performance status
        this.updateVitalStatus('lcp', data.lcp, [2.5, 4.0]);
        this.updateVitalStatus('fid', data.fid / 1000, [0.1, 0.3]);
        this.updateVitalStatus('cls', data.cls, [0.1, 0.25]);
        
        // Update network metrics
        document.getElementById('ttfb').textContent = `${data.ttfb}ms`;
        document.getElementById('fcp').textContent = `${(data.fcp * 1000).toFixed(0)}ms`;
        document.getElementById('lcp-metric').textContent = `${(data.lcp * 1000).toFixed(0)}ms`;
    }
    
    updateVitalStatus(vitalName, value, thresholds) {
        const statusElement = document.getElementById(`${vitalName}-status`);
        let status = 'good';
        
        if (value > thresholds[1]) {
            status = 'poor';
        } else if (value > thresholds[0]) {
            status = 'needs-improvement';
        }
        
        statusElement.textContent = status.replace('-', ' ');
        statusElement.className = `vital-status ${status}`;
    }
    
    updateCostAlerts() {
        const alertsContainer = document.getElementById('cost-alerts');
        const alerts = this.generateCostAlerts();
        
        alertsContainer.innerHTML = '';
        
        alerts.forEach(alert => {
            const alertElement = document.createElement('div');
            alertElement.className = `alert alert-${alert.type}`;
            alertElement.innerHTML = `
                <div class="alert-content">
                    <div class="alert-title">${alert.title}</div>
                    <div class="alert-message">${alert.message}</div>
                </div>
                <div class="alert-time">${alert.time}</div>
            `;
            alertsContainer.appendChild(alertElement);
        });
    }
    
    generateCostAlerts() {
        const alerts = [];
        const data = this.costData;
        
        // Check for high costs
        if (data.total > 15) {
            alerts.push({
                type: 'danger',
                title: 'High Monthly Cost',
                message: `Monthly costs ($${data.total.toFixed(2)}) exceed recommended threshold.`,
                time: new Date().toLocaleTimeString()
            });
        } else if (data.total > 10) {
            alerts.push({
                type: 'warning',
                title: 'Cost Alert',
                message: `Monthly costs ($${data.total.toFixed(2)}) are approaching threshold.`,
                time: new Date().toLocaleTimeString()
            });
        }
        
        // Check for high CloudFront costs
        if (data.cloudfront > 5) {
            alerts.push({
                type: 'warning',
                title: 'High CloudFront Costs',
                message: `CloudFront costs ($${data.cloudfront.toFixed(2)}) are high. Consider optimizing caching.`,
                time: new Date().toLocaleTimeString()
            });
        }
        
        // Check for high S3 costs
        if (data.s3 > 3) {
            alerts.push({
                type: 'warning',
                title: 'High S3 Costs',
                message: `S3 costs ($${data.s3.toFixed(2)}) are high. Consider storage optimization.`,
                time: new Date().toLocaleTimeString()
            });
        }
        
        // Add success alert if no issues
        if (alerts.length === 0) {
            alerts.push({
                type: 'success',
                title: 'Costs Within Limits',
                message: 'All service costs are within acceptable limits.',
                time: new Date().toLocaleTimeString()
            });
        }
        
        return alerts;
    }
    
    calculateCostTrend() {
        // Simulate cost trend calculation
        const trends = ['No change', 'Slight increase', 'Slight decrease', 'Stable'];
        return trends[Math.floor(Math.random() * trends.length)];
    }
    
    updateLastUpdated() {
        const now = new Date();
        const timeString = now.toLocaleString();
        
        document.getElementById('last-updated').textContent = timeString;
        document.getElementById('cost-last-updated').textContent = `Last updated: ${timeString}`;
        document.getElementById('health-last-updated').textContent = `Last updated: ${timeString}`;
        document.getElementById('performance-last-updated').textContent = `Last updated: ${timeString}`;
    }
    
    showError(message) {
        console.error(message);
        
        // Create error alert
        const alertElement = document.createElement('div');
        alertElement.className = 'alert alert-danger';
        alertElement.innerHTML = `
            <div class="alert-content">
                <div class="alert-title">Error</div>
                <div class="alert-message">${message}</div>
            </div>
            <div class="alert-time">${new Date().toLocaleTimeString()}</div>
        `;
        
        // Add to alerts container
        const alertsContainer = document.getElementById('alerts-container');
        if (alertsContainer) {
            alertsContainer.appendChild(alertElement);
        }
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new AWSMonitoringDashboard();
});

// Export for potential use in other scripts
window.AWSMonitoringDashboard = AWSMonitoringDashboard;
