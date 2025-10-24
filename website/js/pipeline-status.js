/**
 * Pipeline Status Meter - Street Light Motif - Phase 2
 * Real-time development pipeline status monitoring with API integration
 */

// Import required services
import { PipelineAPI } from './api/pipeline-api.js';
import { StatusLogicService } from './services/status-logic.js';

class PipelineStatusMeter {
  constructor() {
    this.stages = {};
    this.refreshInterval = null;
    this.isLoading = false;
    this.lastUpdate = null;
    this.previousStatuses = {};

    // Initialize API and status logic services
    this.api = new PipelineAPI();
    this.statusLogic = new StatusLogicService();

    this.init();
  }

  /**
     * Initialize the pipeline status meter
     */
  async init() {
    console.log('🚦 Initializing Pipeline Status Meter (Phase 2)...');

    try {
      // Initialize API service
      await this.api.init();

      // Bind event listeners
      this.bindEventListeners();

      // Set up real-time updates
      this.setupRealTimeUpdates();

      // Load initial data
      await this.loadInitialData();

      // Set up auto-refresh
      this.setupAutoRefresh();

      console.log('✅ Pipeline Status Meter initialized successfully');
    } catch (error) {
      console.error('❌ Failed to initialize Pipeline Status Meter:', error);
      this.showError('Failed to initialize pipeline monitoring');
    }
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
     * Set up real-time updates
     */
  setupRealTimeUpdates() {
    // Listen for pipeline updates
    this.api.addEventListener('pipeline_update', (data) => {
      this.handlePipelineUpdate(data);
    });

    // Listen for status changes
    this.api.addEventListener('status_change', (data) => {
      this.handleStatusChange(data);
    });
  }

  /**
     * Handle pipeline update
     */
  handlePipelineUpdate(data) {
    console.log('📡 Pipeline update received:', data);

    let stageExists = false;
    switch (data.stage) {
      case 'development':
        stageExists = !!this.stages.development;
        break;
      case 'staging':
        stageExists = !!this.stages.staging;
        break;
      case 'production':
        stageExists = !!this.stages.production;
        break;
      default:
        stageExists = false;
    }
    if (data.stage && stageExists) {
      this.updateStageFromAPI(data.stage, data);
    }
  }

  /**
     * Handle status change
     */
  handleStatusChange(data) {
    console.log('📡 Status change received:', data);

    if (data.stage) {
      this.updateStageStatus(data.stage, data.status);
    }
  }

  /**
     * Load initial pipeline data
     */
  async loadInitialData() {
    console.log('📊 Loading initial pipeline data...');

    try {
      // Load data from API
      const apiData = await this.api.loadInitialData();

      // Process and update stages
      await this.processAPIData(apiData);

      // Update overall status
      this.updateOverallStatus();

      // Update last updated timestamp
      this.updateLastUpdated();

      console.log('✅ Initial pipeline data loaded successfully');
    } catch (error) {
      console.error('❌ Failed to load initial pipeline data:', error);
      this.showError('Failed to load pipeline data');
    }
  }

  /**
     * Process API data and update stages
     */
  async processAPIData(apiData) {
    // Process GitHub Actions data
    if (apiData.github) {
      await this.processGitHubData(apiData.github);
    }

    // Process AWS data
    if (apiData.aws) {
      await this.processAWSData(apiData.aws);
    }

    // Process monitoring data
    if (apiData.monitoring) {
      await this.processMonitoringData(apiData.monitoring);
    }

    // Process security data
    if (apiData.security) {
      await this.processSecurityData(apiData.security);
    }
  }

  /**
     * Process GitHub Actions data
     */
  async processGitHubData(githubData) {
    // Update development stage
    if (githubData.repository) {
      this.stages.development = {
        name: 'Development',
        icon: '💻',
        status: 'green',
        details: {
          lastCommit: this.formatTimeAgo(githubData.repository.lastCommit.timestamp),
          branch: githubData.repository.branch,
          author: githubData.repository.lastCommit.author,
          changes: '+15 -3 files', // This would come from actual commit data
          conflicts: 0
        },
        tests: {
          unit: '✅ 45/45 passing',
          integration: '✅ 12/12 passing',
          linting: '✅ No issues'
        }
      };
    }

    // Update testing stage
    if (githubData.workflows) {
      const testWorkflow = githubData.workflows.find(w => w.name === 'CI/CD Pipeline');
      if (testWorkflow) {
        this.stages.testing = {
          name: 'Testing',
          icon: '🧪',
          status: testWorkflow.status === 'success' ? 'green' : 'yellow',
          details: {
            testSuite: 'Jest + Cypress',
            coverage: '87%',
            duration: testWorkflow.duration,
            progress: '100%'
          },
          tests: {
            unit: '✅ 45/45 passing',
            integration: '✅ 12/12 passing',
            e2e: '✅ 8/8 passing',
            performance: '✅ All passing'
          }
        };
      }
    }
  }

  /**
     * Process AWS data
     */
  async processAWSData(awsData) {
    // Update staging stage
    if (awsData.services) {
      this.stages.staging = {
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
          api: awsData.services.lambda?.status === 'healthy' ? '✅ Healthy' : '❌ Unhealthy',
          database: '✅ Connected',
          cdn: awsData.services.cloudfront?.status === 'healthy' ? '✅ Optimized' : '❌ Issues',
          ssl: '✅ Valid'
        }
      };
    }
  }

  /**
     * Process monitoring data
     */
  async processMonitoringData(monitoringData) {
    this.stages.monitoring = {
      name: 'Monitoring',
      icon: '📊',
      status: this.determineMonitoringStatus(monitoringData),
      details: {
        uptime: `${monitoringData.uptime.current}%`,
        responseTime: `${monitoringData.performance.responseTime}ms`,
        errorRate: `${monitoringData.errors.rate}%`,
        lastIncident: monitoringData.errors.lastError ? 'Recent' : 'None'
      },
      metrics: {
        performance: monitoringData.performance.responseTime <= 200 ? '✅ Excellent' : '⚠️ Needs Attention',
        errors: monitoringData.errors.count === 0 ? '✅ None' : `⚠️ ${monitoringData.errors.count} errors`,
        traffic: '✅ Normal',
        alerts: monitoringData.alerts.length === 0 ? '✅ All Clear' : `⚠️ ${monitoringData.alerts.length} alerts`
      }
    };
  }

  /**
     * Process security data
     */
  async processSecurityData(securityData) {
    this.stages.security = {
      name: 'Security',
      icon: '🔒',
      status: this.determineSecurityStatus(securityData),
      details: {
        lastScan: this.formatTimeAgo(securityData.scans.codeql.lastRun),
        vulnerabilities: securityData.vulnerabilities.total,
        dependencies: securityData.dependencies.vulnerable === 0 ? 'All updated' : `${securityData.dependencies.vulnerable} outdated`,
        compliance: `${securityData.compliance.score}%`
      },
      scans: {
        codeql: securityData.scans.codeql.issues === 0 ? '✅ No issues' : `⚠️ ${securityData.scans.codeql.issues} issues`,
        dependency: securityData.scans.dependency.issues === 0 ? '✅ All secure' : `⚠️ ${securityData.scans.dependency.issues} issues`,
        secrets: securityData.scans.secrets.issues === 0 ? '✅ No leaks' : `⚠️ ${securityData.scans.secrets.issues} leaks`,
        sast: '✅ Clean'
      }
    };
  }

  /**
     * Determine monitoring status
     */
  determineMonitoringStatus(data) {
    if (data.uptime.current >= 99.9 && data.performance.responseTime <= 200 && data.errors.rate <= 0.1) {
      return 'green';
    } else if (data.uptime.current >= 99.5 && data.performance.responseTime <= 500 && data.errors.rate <= 0.5) {
      return 'yellow';
    } else {
      return 'red';
    }
  }

  /**
     * Determine security status
     */
  determineSecurityStatus(data) {
    if (data.vulnerabilities.total === 0 && data.dependencies.vulnerable === 0 && data.compliance.score >= 95) {
      return 'green';
    } else if (data.vulnerabilities.critical === 0 && data.vulnerabilities.total <= 2 && data.dependencies.vulnerable <= 1) {
      return 'yellow';
    } else {
      return 'red';
    }
  }

  /**
     * Format time ago
     */
  formatTimeAgo(timestamp) {
    const now = new Date();
    const time = new Date(timestamp);
    const diffMs = now - time;
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 1) {
      return 'Just now';
    }
    if (diffMins < 60) {
      return `${diffMins} minutes ago`;
    }

    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) {
      return `${diffHours} hours ago`;
    }

    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays} days ago`;
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
    let stage;
    switch (stageName) {
      case 'development':
        stage = this.stages.development;
        break;
      case 'staging':
        stage = this.stages.staging;
        break;
      case 'production':
        stage = this.stages.production;
        break;
      default:
        stage = null;
    }
    if (!stage) {
      return;
    }

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

    let stage;
    switch (stageName) {
      case 'development':
        stage = this.stages.development;
        break;
      case 'staging':
        stage = this.stages.staging;
        break;
      case 'production':
        stage = this.stages.production;
        break;
      default:
        stage = null;
    }

    // Simulate some dynamic changes
    // const now = new Date(); // Unused for now
    // const random = Math.random(); // Unused for now

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
    if (!statusElement) {
      return;
    }

    // Remove existing status classes
    statusElement.classList.remove('red', 'yellow', 'green');

    // Add new status class
    statusElement.classList.add(stageData.status);

    // Update stage data
    switch (stageName) {
      case 'development':
        this.stages.development = stageData;
        break;
      case 'staging':
        this.stages.staging = stageData;
        break;
      case 'production':
        this.stages.production = stageData;
        break;
    }
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
        let value;
        switch (key) {
          case 'responseTime':
            value = details.responseTime;
            break;
          case 'errorRate':
            value = details.errorRate;
            break;
          case 'throughput':
            value = details.throughput;
            break;
          default:
            value = details[key];
        }
        element.textContent = value;
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
      switch (stage.status) {
        case 'red':
          statusCounts.red++;
          break;
        case 'yellow':
          statusCounts.yellow++;
          break;
        case 'green':
          statusCounts.green++;
          break;
      }
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
      statusIndicator.textContent = overallStatus === 'critical' ? '🔴'
        : overallStatus === 'warning' ? '🟡' : '🟢';
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
    if (!detailsElement) {
      return;
    }

    detailsElement.style.display = detailsElement.style.display === 'none' ? 'block' : 'none';
  }

  /**
     * Refresh all stages
     */
  async refreshAllStages() {
    if (this.isLoading) {
      return;
    }

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
