/**
 * Status Logic Service - Phase 2 Implementation
 * Comprehensive status determination logic for pipeline stages
 */

class StatusLogicService {
  constructor() {
    this.statusRules = {
      development: {
        green: (data) => {
          return data.tests.unit === 'success' &&
                           data.tests.integration === 'success' &&
                           data.conflicts === 0 &&
                           data.lastCommit.age < 30; // minutes
        },
        yellow: (data) => {
          return data.tests.unit === 'success' &&
                           data.tests.integration === 'running' &&
                           data.conflicts === 0;
        },
        red: (data) => {
          return data.tests.unit === 'failed' ||
                           data.tests.integration === 'failed' ||
                           data.conflicts > 0;
        }
      },
      testing: {
        green: (data) => {
          return data.coverage >= 80 &&
                           data.tests.unit === 'success' &&
                           data.tests.integration === 'success' &&
                           data.tests.e2e === 'success';
        },
        yellow: (data) => {
          return data.tests.unit === 'success' &&
                           (data.tests.integration === 'running' ||
                            data.tests.e2e === 'running' ||
                            data.coverage < 80);
        },
        red: (data) => {
          return data.tests.unit === 'failed' ||
                           data.tests.integration === 'failed' ||
                           data.tests.e2e === 'failed';
        }
      },
      staging: {
        green: (data) => {
          return data.uptime >= 99.5 &&
                           data.health.api === 'healthy' &&
                           data.health.database === 'healthy' &&
                           data.health.cdn === 'healthy';
        },
        yellow: (data) => {
          return data.uptime >= 99.0 &&
                           data.uptime < 99.5 &&
                           data.health.api === 'healthy';
        },
        red: (data) => {
          return data.uptime < 99.0 ||
                           data.health.api === 'unhealthy' ||
                           data.health.database === 'unhealthy';
        }
      },
      security: {
        green: (data) => {
          return data.vulnerabilities.total === 0 &&
                           data.dependencies.vulnerable === 0 &&
                           data.compliance.score >= 95;
        },
        yellow: (data) => {
          return data.vulnerabilities.total <= 2 &&
                           data.vulnerabilities.critical === 0 &&
                           data.dependencies.vulnerable <= 1;
        },
        red: (data) => {
          return data.vulnerabilities.critical > 0 ||
                           data.vulnerabilities.total > 2 ||
                           data.dependencies.vulnerable > 1;
        }
      },
      deployment: {
        green: (data) => {
          return data.status === 'completed' &&
                           data.verification === 'success' &&
                           data.rollback === false;
        },
        yellow: (data) => {
          return data.status === 'in_progress' ||
                           data.status === 'pending' ||
                           data.verification === 'running';
        },
        red: (data) => {
          return data.status === 'failed' ||
                           data.verification === 'failed' ||
                           data.rollback === true;
        }
      },
      monitoring: {
        green: (data) => {
          return data.uptime >= 99.9 &&
                           data.responseTime <= 200 &&
                           data.errorRate <= 0.1 &&
                           data.alerts.length === 0;
        },
        yellow: (data) => {
          return (data.uptime >= 99.5 && data.uptime < 99.9) ||
                           (data.responseTime > 200 && data.responseTime <= 500) ||
                           (data.errorRate > 0.1 && data.errorRate <= 0.5) ||
                           data.alerts.length <= 2;
        },
        red: (data) => {
          return data.uptime < 99.5 ||
                           data.responseTime > 500 ||
                           data.errorRate > 0.5 ||
                           data.alerts.length > 2;
        }
      }
    };
  }

  /**
     * Determine status for a specific stage
     */
  determineStatus(stage, data) {
    let rules;
    switch (stage) {
      case 'development':
        rules = this.statusRules.development;
        break;
      case 'staging':
        rules = this.statusRules.staging;
        break;
      case 'production':
        rules = this.statusRules.production;
        break;
      default:
        rules = null;
    }
    if (!rules) {
      console.warn(`No status rules found for stage: ${stage}`);
      return 'unknown';
    }

    // Check rules in order of severity
    if (rules.red && rules.red(data)) {
      return 'red';
    } else if (rules.yellow && rules.yellow(data)) {
      return 'yellow';
    } else if (rules.green && rules.green(data)) {
      return 'green';
    }

    return 'unknown';
  }

  /**
     * Determine overall pipeline status
     */
  determineOverallStatus(stageStatuses) {
    const statusCounts = {
      red: 0,
      yellow: 0,
      green: 0,
      unknown: 0
    };

    Object.values(stageStatuses).forEach(status => {
      switch (status) {
        case 'green':
          statusCounts.green++;
          break;
        case 'yellow':
          statusCounts.yellow++;
          break;
        case 'red':
          statusCounts.red++;
          break;
        case 'unknown':
          statusCounts.unknown++;
          break;
      }
    });

    // Overall status logic
    if (statusCounts.red > 0) {
      return {
        status: 'critical',
        text: `${statusCounts.red} Critical Issue${statusCounts.red > 1 ? 's' : ''}`,
        icon: '🔴',
        color: '#ef4444'
      };
    } else if (statusCounts.yellow > 0) {
      return {
        status: 'warning',
        text: `${statusCounts.yellow} Stage${statusCounts.yellow > 1 ? 's' : ''} In Progress`,
        icon: '🟡',
        color: '#f59e0b'
      };
    } else if (statusCounts.green > 0) {
      return {
        status: 'healthy',
        text: 'All Systems Operational',
        icon: '🟢',
        color: '#10b981'
      };
    } else {
      return {
        status: 'unknown',
        text: 'Status Unknown',
        icon: '⚪',
        color: '#6b7280'
      };
    }
  }

  /**
     * Get status priority for sorting
     */
  getStatusPriority(status) {
    const priorities = {
      red: 4,
      yellow: 3,
      green: 2,
      unknown: 1
    };
    let priority;
    switch (status) {
      case 'critical':
        priority = 4;
        break;
      case 'warning':
        priority = 3;
        break;
      case 'info':
        priority = 2;
        break;
      case 'success':
        priority = 1;
        break;
      default:
        priority = 0;
    }
    return priority;
  }

  /**
     * Get status description
     */
  getStatusDescription(stage, status) {
    const descriptions = {
      development: {
        green: 'Development environment is healthy with all tests passing',
        yellow: 'Development in progress with some tests running',
        red: 'Development has critical issues requiring attention'
      },
      testing: {
        green: 'All tests passing with good coverage',
        yellow: 'Tests in progress or coverage below threshold',
        red: 'Test failures detected requiring fixes'
      },
      staging: {
        green: 'Staging environment is healthy and ready',
        yellow: 'Staging environment has minor issues',
        red: 'Staging environment has critical issues'
      },
      security: {
        green: 'No security vulnerabilities detected',
        yellow: 'Minor security issues requiring attention',
        red: 'Critical security vulnerabilities detected'
      },
      deployment: {
        green: 'Deployment completed successfully',
        yellow: 'Deployment in progress',
        red: 'Deployment failed or rolled back'
      },
      monitoring: {
        green: 'All systems monitoring healthy',
        yellow: 'Some monitoring alerts or performance issues',
        red: 'Critical monitoring alerts or system issues'
      }
    };

    let description;
    if (stage === 'development') {
      switch (status) {
        case 'green':
          description = 'Development is progressing well';
          break;
        case 'yellow':
          description = 'Development has some issues';
          break;
        case 'red':
          description = 'Development is blocked';
          break;
        default:
          description = 'Development status unknown';
      }
    } else if (stage === 'staging') {
      switch (status) {
        case 'green':
          description = 'Staging environment is healthy';
          break;
        case 'yellow':
          description = 'Staging has minor issues';
          break;
        case 'red':
          description = 'Staging environment is down';
          break;
        default:
          description = 'Staging status unknown';
      }
    } else if (stage === 'production') {
      switch (status) {
        case 'green':
          description = 'Production is running smoothly';
          break;
        case 'yellow':
          description = 'Production has minor issues';
          break;
        case 'red':
          description = 'Production is experiencing issues';
          break;
        default:
          description = 'Production status unknown';
      }
    } else {
      description = 'Status unknown';
    }
    return description;
  }

  /**
     * Get recommended actions for status
     */
  getRecommendedActions(stage, status) {
    const actions = {
      development: {
        green: ['Continue development', 'Run additional tests'],
        yellow: ['Wait for tests to complete', 'Check test coverage'],
        red: ['Fix failing tests', 'Resolve conflicts', 'Review code changes']
      },
      testing: {
        green: ['Proceed to staging', 'Review test coverage'],
        yellow: ['Wait for tests to complete', 'Check test results'],
        red: ['Fix failing tests', 'Review test configuration', 'Check dependencies']
      },
      staging: {
        green: ['Proceed to production', 'Run final checks'],
        yellow: ['Monitor staging environment', 'Check service health'],
        red: ['Fix staging issues', 'Check infrastructure', 'Review deployment']
      },
      security: {
        green: ['Continue with deployment', 'Schedule next security scan'],
        yellow: ['Review security issues', 'Update dependencies'],
        red: ['Fix security vulnerabilities', 'Update dependencies', 'Review code']
      },
      deployment: {
        green: ['Monitor production', 'Update documentation'],
        yellow: ['Wait for deployment', 'Monitor progress'],
        red: ['Rollback if necessary', 'Check deployment logs', 'Fix issues']
      },
      monitoring: {
        green: ['Continue monitoring', 'Review metrics'],
        yellow: ['Investigate alerts', 'Check performance'],
        red: ['Address critical issues', 'Check system health', 'Escalate if needed']
      }
    };

    let actions;
    if (stage === 'development') {
      switch (status) {
        case 'green':
          actions = ['Continue development', 'Run additional tests'];
          break;
        case 'yellow':
          actions = ['Wait for tests to complete', 'Check test coverage'];
          break;
        case 'red':
          actions = ['Fix failing tests', 'Resolve conflicts', 'Review code changes'];
          break;
        default:
          actions = ['Check status', 'Review logs'];
      }
    } else if (stage === 'staging') {
      switch (status) {
        case 'green':
          actions = ['Proceed to production', 'Run final checks'];
          break;
        case 'yellow':
          actions = ['Monitor staging environment', 'Check service health'];
          break;
        case 'red':
          actions = ['Fix staging issues', 'Check infrastructure', 'Review deployment'];
          break;
        default:
          actions = ['Check status', 'Review logs'];
      }
    } else if (stage === 'production') {
      switch (status) {
        case 'green':
          actions = ['Monitor production', 'Update documentation'];
          break;
        case 'yellow':
          actions = ['Wait for deployment', 'Monitor progress'];
          break;
        case 'red':
          actions = ['Rollback if necessary', 'Check deployment logs', 'Fix issues'];
          break;
        default:
          actions = ['Check status', 'Review logs'];
      }
    } else {
      actions = ['Check status', 'Review logs'];
    }
    return actions;
  }

  /**
     * Calculate health score
     */
  calculateHealthScore(stageStatuses) {
    const weights = {
      development: 0.15,
      testing: 0.20,
      staging: 0.15,
      security: 0.20,
      deployment: 0.15,
      monitoring: 0.15
    };

    let totalScore = 0;
    let totalWeight = 0;

    Object.entries(stageStatuses).forEach(([stage, status]) => {
      let weight;
      switch (stage) {
        case 'development':
          weight = weights.development || 0;
          break;
        case 'staging':
          weight = weights.staging || 0;
          break;
        case 'production':
          weight = weights.production || 0;
          break;
        default:
          weight = 0;
      }
      const score = this.getStatusScore(status);
      totalScore += score * weight;
      totalWeight += weight;
    });

    return totalWeight > 0 ? Math.round(totalScore / totalWeight) : 0;
  }

  /**
     * Get numeric score for status
     */
  getStatusScore(status) {
    const scores = {
      green: 100,
      yellow: 60,
      red: 0,
      unknown: 30
    };
    let score;
    switch (status) {
      case 'green':
        score = 100;
        break;
      case 'yellow':
        score = 60;
        break;
      case 'red':
        score = 20;
        break;
      case 'unknown':
        score = 30;
        break;
      default:
        score = 0;
    }
    return score;
  }

  /**
     * Get status trend
     */
  getStatusTrend(currentStatuses, previousStatuses) {
    const trends = {};

    Object.keys(currentStatuses).forEach(stage => {
      let currentStatus, previousStatus;
      switch (stage) {
        case 'development':
          currentStatus = currentStatuses.development;
          previousStatus = previousStatuses.development || 'unknown';
          break;
        case 'staging':
          currentStatus = currentStatuses.staging;
          previousStatus = previousStatuses.staging || 'unknown';
          break;
        case 'production':
          currentStatus = currentStatuses.production;
          previousStatus = previousStatuses.production || 'unknown';
          break;
        default:
          currentStatus = 'unknown';
          previousStatus = 'unknown';
      }
      
      const current = this.getStatusScore(currentStatus);
      const previous = this.getStatusScore(previousStatus);

      if (current > previous) {
        trends[stage] = 'improving';
      } else if (current < previous) {
        trends[stage] = 'declining';
      } else {
        trends[stage] = 'stable';
      }
    });

    return trends;
  }

  /**
     * Validate stage data
     */
  validateStageData(stage, data) {
    const requiredFields = {
      development: ['tests', 'conflicts', 'lastCommit'],
      testing: ['coverage', 'tests'],
      staging: ['uptime', 'health'],
      security: ['vulnerabilities', 'dependencies', 'compliance'],
      deployment: ['status', 'verification'],
      monitoring: ['uptime', 'responseTime', 'errorRate', 'alerts']
    };

    let fields;
    switch (stage) {
      case 'development':
        fields = ['tests', 'conflicts', 'lastCommit'];
        break;
      case 'testing':
        fields = ['coverage', 'tests'];
        break;
      case 'staging':
        fields = ['uptime', 'health'];
        break;
      case 'security':
        fields = ['vulnerabilities', 'dependencies', 'compliance'];
        break;
      case 'deployment':
        fields = ['status', 'verification'];
        break;
      case 'monitoring':
        fields = ['uptime', 'responseTime', 'errorRate', 'alerts'];
        break;
      default:
        fields = [];
    }
    const missing = fields.filter(field => !(field in data));

    if (missing.length > 0) {
      console.warn(`Missing required fields for ${stage}:`, missing);
      return false;
    }

    return true;
  }
}

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = StatusLogicService;
}
