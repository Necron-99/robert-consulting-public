/**
 * Pipeline Status Meter - Street Light Motif
 * Real-time development pipeline status monitoring
 */

class PipelineStatusMeter {
    constructor() {
        this.stages = {
            development: {
                name: 'Development',
                icon: '💻',
                status: 'green',
                details: {
                    lastCommit: '2 minutes ago',
                    branch: 'feature/new-feature',
                    author: 'Developer',
                    changes: '+15 -3 files',
                    conflicts: 0
                },
                tests: {
                    unit: '✅ 45/45 passing',
                    integration: '✅ 12/12 passing',
                    linting: '✅ No issues'
                }
            },
            testing: {
                name: 'Testing',
                icon: '🧪',
                status: 'yellow',
                details: {
                    testSuite: 'Jest + Cypress',
                    coverage: '87%',
                    duration: '2m 34s',
                    progress: '65%'
                },
                tests: {
                    unit: '✅ 45/45 passing',
                    integration: '🔄 8/12 passing',
                    e2e: '⏳ Queued',
                    performance: '⏳ Queued'
                }
            },
            staging: {
                name: 'Staging',
                icon: '🚀',
                status: 'green',
                details: {
                    environment: 'staging.robertconsulting.net',
                    deployment: 'v1.2.3',
                    uptime: '99.9%',
                    lastDeploy: '15 minutes ago'
                },
                health: {
                    api: '✅ Healthy',
                    database: '✅ Connected',
                    cdn: '✅ Optimized',
                    ssl: '✅ Valid'
                }
            },
            security: {
                name: 'Security',
                icon: '🔒',
                status: 'green',
                details: {
                    lastScan: '1 hour ago',
                    vulnerabilities: 0,
                    dependencies: 'All updated',
                    compliance: '100%'
                },
                scans: {
                    codeql: '✅ No issues',
                    dependency: '✅ All secure',
                    secrets: '✅ No leaks',
                    sast: '✅ Clean'
                }
            },
            deployment: {
                name: 'Deployment',
                icon: '🚀',
                status: 'yellow',
                details: {
                    target: 'production',
                    strategy: 'Blue-Green',
                    progress: '75%',
                    estimatedTime: '3 minutes'
                },
                steps: {
                    build: '✅ Complete',
                    test: '✅ Complete',
                    deploy: '🔄 In Progress',
                    verify: '⏳ Pending'
                }
            },
            monitoring: {
                name: 'Monitoring',
                icon: '📊',
                status: 'green',
                details: {
                    uptime: '99.9%',
                    responseTime: '120ms',
                    errorRate: '0.01%',
                    lastIncident: 'None'
                },
                metrics: {
                    performance: '✅ Excellent',
                    errors: '✅ None',
                    traffic: '✅ Normal',
                    alerts: '✅ All Clear'
                }
            }
        };
        
        this.refreshInterval = null;
        this.isLoading = false;
        this.lastUpdate = null;
        
        this.init();
    }

    /**
     * Initialize the pipeline status meter
     */
    init() {
        console.log('🚦 Initializing Pipeline Status Meter...');
        
        // Bind event listeners
        this.bindEventListeners();
        
        // Load initial data
        this.loadInitialData();
        
        // Set up auto-refresh
        this.setupAutoRefresh();
        
        console.log('✅ Pipeline Status Meter initialized');
    }

    /**
     * Bind event listeners
     */
    bindEventListeners() {
        // Stage card click handlers
        const stageCards = document.querySelectorAll('.stage-card');
        stageCards.forEach(card => {
            card.addEventListener('click', (e) => {
                const stage = e.currentTarget.dataset.stage;
                this.toggleStageDetails(stage);
            });
        });

        // Global refresh
        const refreshButton = document.getElementById('refresh-pipeline');
        if (refreshButton) {
            refreshButton.addEventListener('click', () => {
                this.refreshAllStages();
            });
        }
    }

    /**
     * Load initial pipeline data
     */
    async loadInitialData() {
        console.log('📊 Loading initial pipeline data...');
        
        try {
            await this.updateAllStages();
            this.updateOverallStatus();
            this.updateLastUpdated();
            console.log('✅ Initial pipeline data loaded successfully');
        } catch (error) {
            console.error('❌ Failed to load initial pipeline data:', error);
            this.showError('Failed to load pipeline data');
        }
    }

    /**
     * Update all pipeline stages
     */
    async updateAllStages() {
        const stages = Object.keys(this.stages);
        
        for (const stage of stages) {
            await this.updateStage(stage);
        }
    }

    /**
     * Update a specific stage
     */
    async updateStage(stageName) {
        const stage = this.stages[stageName];
        if (!stage) return;

        // Simulate API call - replace with actual data sources
        const stageData = await this.fetchStageData(stageName);
        
        // Update stage status
        this.updateStageStatus(stageName, stageData);
        
        // Update stage details
        this.updateStageDetails(stageName, stageData);
    }

    /**
     * Fetch stage data (simulate API call)
     */
    async fetchStageData(stageName) {
        // Simulate API delay
        await new Promise(resolve => setTimeout(resolve, 100));
        
        const stage = this.stages[stageName];
        
        // Simulate some dynamic changes
        const now = new Date();
        const random = Math.random();
        
        switch (stageName) {
            case 'development':
                return {
                    ...stage,
                    details: {
                        ...stage.details,
                        lastCommit: `${Math.floor(Math.random() * 10)} minutes ago`,
                        changes: `+${Math.floor(Math.random() * 20)} -${Math.floor(Math.random() * 5)} files`
                    }
                };
                
            case 'testing':
                return {
                    ...stage,
                    details: {
                        ...stage.details,
                        coverage: `${Math.floor(80 + Math.random() * 20)}%`,
                        progress: `${Math.floor(50 + Math.random() * 50)}%`
                    }
                };
                
            case 'staging':
                return {
                    ...stage,
                    details: {
                        ...stage.details,
                        uptime: `${(99.5 + Math.random() * 0.5).toFixed(1)}%`
                    }
                };
                
            case 'security':
                return {
                    ...stage,
                    details: {
                        ...stage.details,
                        vulnerabilities: Math.floor(Math.random() * 3)
                    }
                };
                
            case 'deployment':
                return {
                    ...stage,
                    details: {
                        ...stage.details,
                        progress: `${Math.floor(60 + Math.random() * 40)}%`,
                        estimatedTime: `${Math.floor(1 + Math.random() * 5)} minutes`
                    }
                };
                
            case 'monitoring':
                return {
                    ...stage,
                    details: {
                        ...stage.details,
                        responseTime: `${Math.floor(100 + Math.random() * 100)}ms`,
                        errorRate: `${(Math.random() * 0.1).toFixed(2)}%`
                    }
                };
                
            default:
                return stage;
        }
    }

    /**
     * Update stage status indicator
     */
    updateStageStatus(stageName, stageData) {
        const statusElement = document.getElementById(`${stageName}-status`);
        if (!statusElement) return;

        // Remove existing status classes
        statusElement.classList.remove('red', 'yellow', 'green');
        
        // Add new status class
        statusElement.classList.add(stageData.status);
        
        // Update stage data
        this.stages[stageName] = stageData;
    }

    /**
     * Update stage details
     */
    updateStageDetails(stageName, stageData) {
        const details = stageData.details;
        
        // Update specific detail elements
        Object.keys(details).forEach(key => {
            const element = document.getElementById(`${stageName}-${key}`);
            if (element) {
                element.textContent = details[key];
            }
        });
    }

    /**
     * Update overall pipeline status
     */
    updateOverallStatus() {
        const stages = Object.values(this.stages);
        const statusCounts = {
            red: 0,
            yellow: 0,
            green: 0
        };
        
        stages.forEach(stage => {
            statusCounts[stage.status]++;
        });
        
        let overallStatus = 'green';
        let overallText = 'All Systems Operational';
        
        if (statusCounts.red > 0) {
            overallStatus = 'critical';
            overallText = `${statusCounts.red} Critical Issue${statusCounts.red > 1 ? 's' : ''}`;
        } else if (statusCounts.yellow > 0) {
            overallStatus = 'warning';
            overallText = `${statusCounts.yellow} Stage${statusCounts.yellow > 1 ? 's' : ''} In Progress`;
        }
        
        // Update overall status indicator
        const statusIndicator = document.getElementById('overall-status');
        const statusText = document.getElementById('overall-text');
        
        if (statusIndicator) {
            statusIndicator.className = `status-indicator overall-${overallStatus}`;
            statusIndicator.textContent = overallStatus === 'critical' ? '🔴' : 
                                       overallStatus === 'warning' ? '🟡' : '🟢';
        }
        
        if (statusText) {
            statusText.textContent = overallText;
        }
    }

    /**
     * Toggle stage details visibility
     */
    toggleStageDetails(stageName) {
        const detailsElement = document.getElementById(`${stageName}-details`);
        if (!detailsElement) return;
        
        detailsElement.style.display = detailsElement.style.display === 'none' ? 'block' : 'none';
    }

    /**
     * Refresh all stages
     */
    async refreshAllStages() {
        if (this.isLoading) return;
        
        console.log('🔄 Refreshing all pipeline stages...');
        this.setLoading(true);
        
        try {
            await this.updateAllStages();
            this.updateOverallStatus();
            this.updateLastUpdated();
            console.log('✅ All pipeline stages refreshed');
        } catch (error) {
            console.error('❌ Failed to refresh pipeline stages:', error);
            this.showError('Failed to refresh pipeline data');
        } finally {
            this.setLoading(false);
        }
    }

    /**
     * Set loading state
     */
    setLoading(loading) {
        this.isLoading = loading;
        const stageCards = document.querySelectorAll('.stage-card');
        stageCards.forEach(card => {
            if (loading) {
                card.classList.add('loading');
            } else {
                card.classList.remove('loading');
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
        // Auto-refresh every 30 seconds
        this.refreshInterval = setInterval(() => {
            if (!this.isLoading) {
                this.refreshAllStages();
            }
        }, 30 * 1000);
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
    window.pipelineStatusMeter = new PipelineStatusMeter();
});

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (window.pipelineStatusMeter) {
        window.pipelineStatusMeter.destroy();
    }
});
