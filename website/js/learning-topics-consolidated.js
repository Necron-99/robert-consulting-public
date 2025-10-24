/**
 * Consolidated Learning Topics Management
 * Category-based approach with expandable sub-topics
 */

class ConsolidatedLearningTopics {
  constructor() {
    this.categories = [];
    this.currentExpanded = null;
    this.searchTerm = '';
    this.init();
  }

  init() {
    this.loadCategories();
    this.setupEventListeners();
    this.renderCategories();
    this.updateStats();
  }

  loadCategories() {
    this.categories = [
      {
        id: 'current-projects',
        title: 'Current Projects',
        description: 'Active development work and recent achievements',
        icon: '🎬',
        featured: true,
        status: 'active',
        subTopics: [
          {
            id: 'plex-recommendations',
            title: 'Plex Movie Recommendations',
            description: 'AI-powered movie recommendation system using Plex watch history, TMDB API, and AWS Lambda',
            icon: '🎬',
            status: 'completed',
            achievements: ['40-60% accuracy improvement', '<$1/year cost', '90% cost reduction'],
            tags: ['ai', 'recommendations', 'plex', 'tmdb', 'aws-lambda', 'machine-learning']
          },
          {
            id: 'dashboard-api',
            title: 'Dashboard API Development',
            description: 'Real-time dashboard with live AWS cost data, GitHub statistics, and infrastructure monitoring',
            icon: '📊',
            status: 'completed',
            achievements: ['Live AWS cost data', 'Real-time GitHub stats', 'Infrastructure monitoring'],
            tags: ['aws', 'api', 'real-time', 'monitoring', 'cost-optimization']
          },
          {
            id: 'security-implementation',
            title: 'Advanced Security Implementation',
            description: 'Comprehensive security headers, OWASP ZAP integration, and automated vulnerability scanning',
            icon: '🔒',
            status: 'completed',
            achievements: ['Security headers', 'OWASP ZAP integration', 'Automated scanning'],
            tags: ['security', 'owasp-zap', 'headers', 'compliance']
          }
        ]
      },
      {
        id: 'cloud-infrastructure',
        title: 'Cloud & Infrastructure',
        description: 'AWS services, infrastructure as code, and cost optimization',
        icon: '☁️',
        featured: false,
        status: 'proficient',
        subTopics: [
          {
            id: 'aws-services',
            title: 'AWS Services',
            description: 'S3, CloudFront, Route 53, IAM, Lambda, and cost optimization',
            icon: '☁️',
            status: 'proficient',
            tags: ['cloud', 'aws', 'infrastructure', 's3', 'cloudfront', 'lambda']
          },
          {
            id: 'terraform',
            title: 'Terraform & Infrastructure as Code',
            description: 'Infrastructure provisioning, state management, and automation',
            icon: '🏗️',
            status: 'proficient',
            tags: ['infrastructure', 'terraform', 'iac', 'automation']
          },
          {
            id: 'cost-optimization',
            title: 'Cost Optimization',
            description: 'Resource optimization, monitoring, and cost-effective solutions',
            icon: '💰',
            status: 'proficient',
            tags: ['cost-optimization', 'monitoring', 'efficiency']
          },
          {
            id: 'monitoring',
            title: 'Monitoring & Observability',
            description: 'CloudWatch dashboards, performance tracking, and alerting',
            icon: '📊',
            status: 'proficient',
            tags: ['monitoring', 'cloudwatch', 'observability', 'alerting']
          }
        ]
      },
      {
        id: 'security-devsecops',
        title: 'Security & DevSecOps',
        description: 'Security implementation, compliance, and secure development practices',
        icon: '🔒',
        featured: false,
        status: 'proficient',
        subTopics: [
          {
            id: 'security-headers',
            title: 'Security Headers & Compliance',
            description: 'HTTPS, CSP headers, authentication, and security best practices',
            icon: '🔒',
            status: 'proficient',
            tags: ['security', 'https', 'authentication', 'csp', 'compliance']
          },
          {
            id: 'automated-security',
            title: 'Automated Security Scanning',
            description: 'Security scanning, performance analysis, and quality validation',
            icon: '🔍',
            status: 'proficient',
            tags: ['security', 'automation', 'scanning', 'quality']
          },
          {
            id: 'cicd-security',
            title: 'CI/CD Security Workflows',
            description: 'GitHub Actions, automated deployment, and secure testing',
            icon: '🔄',
            status: 'proficient',
            tags: ['devops', 'cicd', 'github-actions', 'automation', 'security']
          }
        ]
      },
      {
        id: 'frontend-development',
        title: 'Frontend Development',
        description: 'Modern web development, responsive design, and user experience',
        icon: '🎨',
        featured: false,
        status: 'proficient',
        subTopics: [
          {
            id: 'html5-css3',
            title: 'HTML5 & CSS3',
            description: 'Semantic markup, responsive design, and modern web standards',
            icon: '🌐',
            status: 'proficient',
            tags: ['frontend', 'html', 'css', 'responsive', 'accessibility']
          },
          {
            id: 'javascript-modern',
            title: 'Modern JavaScript',
            description: 'ES6+, async programming, and DOM manipulation',
            icon: '⚡',
            status: 'proficient',
            tags: ['frontend', 'javascript', 'es6', 'async', 'dom']
          },
          {
            id: 'interactive-interface',
            title: 'Interactive Learning Interface',
            description: 'Dynamic topic exploration with search, filtering, and responsive design',
            icon: '🎨',
            status: 'completed',
            tags: ['ux', 'ui', 'javascript', 'responsive', 'interactive']
          },
          {
            id: 'performance-optimization',
            title: 'Performance Optimization',
            description: 'Sub-2-second load times through CloudFront optimization and caching',
            icon: '⚡',
            status: 'completed',
            tags: ['performance', 'cloudfront', 'optimization', 'caching']
          }
        ]
      },
      {
        id: 'ai-automation',
        title: 'AI & Automation',
        description: 'AI-powered development tools, automation, and intelligent systems',
        icon: '🤖',
        featured: false,
        status: 'learning',
        subTopics: [
          {
            id: 'github-copilot',
            title: 'GitHub Copilot Integration',
            description: 'AI-powered code suggestions, automated code review, and intelligent development assistance',
            icon: '🤖',
            status: 'proficient',
            tags: ['ai', 'copilot', 'code-assistance', 'automation']
          },
          {
            id: 'automated-code-review',
            title: 'Automated Code Review',
            description: 'Security scanning, performance analysis, and quality validation',
            icon: '🔍',
            status: 'proficient',
            tags: ['ai', 'code-review', 'security-scanning', 'quality']
          },
          {
            id: 'ai-powered-development',
            title: 'AI-Powered Development',
            description: 'AI tools for code generation, testing, and deployment automation',
            icon: '🤖',
            status: 'learning',
            tags: ['ai', 'automation', 'devops', 'code-generation']
          }
        ]
      },
      {
        id: 'learning-development',
        title: 'Learning & Development',
        description: 'Learning methodologies, documentation, and professional growth',
        icon: '📚',
        featured: false,
        status: 'proficient',
        subTopics: [
          {
            id: 'hands-on-learning',
            title: 'Hands-on Learning',
            description: 'Learning by doing, building real projects, and solving actual problems',
            icon: '🎯',
            status: 'proficient',
            tags: ['learning', 'practical', 'projects', 'problem-solving']
          },
          {
            id: 'documentation-driven',
            title: 'Documentation-Driven Development',
            description: 'Comprehensive documentation of processes, decisions, and lessons learned',
            icon: '📚',
            status: 'proficient',
            tags: ['documentation', 'knowledge-base', 'processes']
          },
          {
            id: 'community-learning',
            title: 'Community Learning',
            description: 'Engaging with the developer community, sharing knowledge, and learning from others',
            icon: '🤝',
            status: 'proficient',
            tags: ['community', 'collaboration', 'knowledge-sharing']
          },
          {
            id: 'repository-management',
            title: 'Repository Management',
            description: 'Professional repository practices, security, and open-source contributions',
            icon: '🔧',
            status: 'completed',
            tags: ['git', 'repository', 'maintenance', 'open-source']
          }
        ]
      }
    ];
  }

  setupEventListeners() {
    // Search functionality
    const searchInput = document.getElementById('topic-search');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        this.searchTerm = e.target.value.toLowerCase();
        this.renderCategories();
      });
    }

    // Filter tabs
    const filterTabs = document.querySelectorAll('.filter-tab');
    filterTabs.forEach(tab => {
      tab.addEventListener('click', (e) => {
        const filter = e.target.dataset.filter;
        this.setActiveFilter(filter);
      });
    });
  }

  setActiveFilter(filter) {
    // Update active tab
    document.querySelectorAll('.filter-tab').forEach(tab => {
      tab.classList.remove('active');
    });
    document.querySelector(`[data-filter="${filter}"]`).classList.add('active');

    // Filter categories based on selection
    this.renderCategories();
  }

  renderCategories() {
    const container = document.getElementById('topics-grid');
    if (!container) {
      console.error('❌ topics-grid container not found');
      return;
    }
    console.log('🎯 Rendering categories...', this.categories.length, 'categories found');

    let filteredCategories = this.categories;

    // Apply search filter
    if (this.searchTerm) {
      filteredCategories = this.categories.filter(category => {
        return category.title.toLowerCase().includes(this.searchTerm) ||
                       category.description.toLowerCase().includes(this.searchTerm) ||
                       category.subTopics.some(topic =>
                         topic.title.toLowerCase().includes(this.searchTerm) ||
                           topic.description.toLowerCase().includes(this.searchTerm)
                       );
      });
    }

    // Apply category filter
    const activeFilter = document.querySelector('.filter-tab.active')?.dataset.filter;
    if (activeFilter && activeFilter !== 'all') {
      filteredCategories = filteredCategories.filter(category => {
        return category.id === activeFilter ||
                       (activeFilter === 'current' && category.featured) ||
                       (activeFilter === 'technologies' && ['cloud-infrastructure', 'frontend-development', 'ai-automation'].includes(category.id)) ||
                       (activeFilter === 'methodologies' && category.id === 'learning-development') ||
                       (activeFilter === 'security' && category.id === 'security-devsecops');
      });
    }

    container.innerHTML = filteredCategories.map(category => this.renderCategory(category)).join('');

    // Remove loading message if it exists
    const loadingMessage = document.getElementById('loading-message');
    if (loadingMessage) {
      loadingMessage.remove();
    }

    // Update stats
    this.updateStats();
  }

  renderCategory(category) {
    const isExpanded = this.currentExpanded === category.id;
    const statusClass = this.getStatusClass(category.status);
    const featuredClass = category.featured ? 'featured' : '';

    return `
            <div class="category-card ${featuredClass} ${statusClass}" data-category="${category.id}">
                <div class="category-header" onclick="learningTopics.toggleCategory('${category.id}')">
                    <div class="category-icon">${category.icon}</div>
                    <div class="category-content">
                        <h3 class="category-title">${category.title}</h3>
                        <p class="category-description">${category.description}</p>
                        <div class="category-meta">
                            <span class="status-badge ${statusClass}">${this.getStatusText(category.status)}</span>
                            <span class="topic-count">${category.subTopics.length} topics</span>
                        </div>
                    </div>
                    <div class="expand-icon ${isExpanded ? 'expanded' : ''}">▼</div>
                </div>
                
                <div class="category-topics ${isExpanded ? 'expanded' : ''}">
                    ${category.subTopics.map(topic => this.renderSubTopic(topic)).join('')}
                    <div class="view-all-link">
                        <a href="#" onclick="learningTopics.viewAllTopics('${category.id}')">
                            View All ${category.title} Topics →
                        </a>
                    </div>
                </div>
            </div>
        `;
  }

  renderSubTopic(topic) {
    const statusClass = this.getStatusClass(topic.status);
    const achievements = topic.achievements
      ? `<div class="achievements">
                ${topic.achievements.map(achievement => `<span class="achievement">${achievement}</span>`).join('')}
            </div>` : '';

    return `
            <div class="sub-topic ${statusClass}">
                <div class="sub-topic-header">
                    <div class="sub-topic-icon">${topic.icon}</div>
                    <div class="sub-topic-content">
                        <h4 class="sub-topic-title">${topic.title}</h4>
                        <p class="sub-topic-description">${topic.description}</p>
                        ${achievements}
                    </div>
                    <div class="sub-topic-status">
                        <span class="status-badge ${statusClass}">${this.getStatusText(topic.status)}</span>
                    </div>
                </div>
                <div class="sub-topic-tags">
                    ${topic.tags.map(tag => `<span class="tag">${tag}</span>`).join('')}
                </div>
            </div>
        `;
  }

  toggleCategory(categoryId) {
    this.currentExpanded = this.currentExpanded === categoryId ? null : categoryId;
    this.renderCategories();
  }

  viewAllTopics(categoryId) {
    // This could open a modal or navigate to a detailed view
    console.log(`Viewing all topics for category: ${categoryId}`);
    // For now, just expand the category
    this.toggleCategory(categoryId);
  }

  getStatusClass(status) {
    const statusMap = {
      active: 'status-active',
      completed: 'status-completed',
      proficient: 'status-proficient',
      learning: 'status-learning',
      planned: 'status-planned'
    };
    let statusClass;
    switch (status) {
    case 'active':
      statusClass = 'status-active';
      break;
    case 'completed':
      statusClass = 'status-completed';
      break;
    case 'learning':
      statusClass = 'status-learning';
      break;
    case 'planned':
      statusClass = 'status-planned';
      break;
    default:
      statusClass = 'status-default';
    }
    return statusClass;
  }

  getStatusText(status) {
    const statusMap = {
      active: 'Active',
      completed: 'Completed',
      proficient: 'Proficient',
      learning: 'Learning',
      planned: 'Planned'
    };
    let statusText;
    switch (status) {
    case 'active':
      statusText = 'Active';
      break;
    case 'completed':
      statusText = 'Completed';
      break;
    case 'proficient':
      statusText = 'Proficient';
      break;
    case 'learning':
      statusText = 'Learning';
      break;
    case 'planned':
      statusText = 'Planned';
      break;
    default:
      statusText = 'Unknown';
    }
    return statusText;
  }

  updateStats() {
    const totalCategories = this.categories.length;
    const totalTopics = this.categories.reduce((sum, cat) => sum + cat.subTopics.length, 0);
    // const activeProjects = this.categories.filter(cat => cat.status === 'active').length; // Unused for now

    const totalTopicsEl = document.getElementById('total-topics');
    const filteredTopicsEl = document.getElementById('filtered-topics');

    if (totalTopicsEl) {
      totalTopicsEl.textContent = totalCategories;
    }
    if (filteredTopicsEl) {
      filteredTopicsEl.textContent = totalTopics;
    }
  }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  console.log('🎯 Initializing Consolidated Learning Topics...');
  try {
    window.learningTopics = new ConsolidatedLearningTopics();
    console.log('✅ Consolidated Learning Topics initialized successfully');
  } catch (error) {
    console.error('❌ Error initializing Consolidated Learning Topics:', error);
  }
});
