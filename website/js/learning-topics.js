/**
 * Learning Topics Management
 * Handles dynamic topic display, filtering, and search functionality
 */

class LearningTopics {
    constructor() {
        this.topics = [];
        this.filteredTopics = [];
        this.currentFilter = 'all';
        this.searchTerm = '';
        this.init();
    }

    init() {
        this.loadTopics();
        this.setupEventListeners();
        this.renderTopics();
        this.updateStats();
    }

    loadTopics() {
        // Define all topics with their metadata
        this.topics = [
            // Technology Topics
            {
                id: 'html5',
                title: 'HTML5',
                description: 'Semantic markup, accessibility, and modern web standards',
                category: 'technologies',
                subcategory: 'Frontend Development',
                icon: '🌐',
                tags: ['frontend', 'html', 'web-standards', 'accessibility'],
                type: 'technology'
            },
            {
                id: 'css3',
                title: 'CSS3',
                description: 'Responsive design, animations, and modern layout techniques',
                category: 'technologies',
                subcategory: 'Frontend Development',
                icon: '🎨',
                tags: ['frontend', 'css', 'design', 'responsive', 'animations'],
                type: 'technology'
            },
            {
                id: 'javascript',
                title: 'JavaScript ES6+',
                description: 'Modern JavaScript, async programming, and DOM manipulation',
                category: 'technologies',
                subcategory: 'Frontend Development',
                icon: '⚡',
                tags: ['frontend', 'javascript', 'programming', 'es6', 'async'],
                type: 'technology'
            },
            {
                id: 'aws-services',
                title: 'AWS Services',
                description: 'S3, CloudFront, Route 53, IAM, and cost optimization',
                category: 'technologies',
                subcategory: 'Cloud Infrastructure',
                icon: '☁️',
                tags: ['cloud', 'aws', 'infrastructure', 's3', 'cloudfront'],
                type: 'technology'
            },
            {
                id: 'terraform',
                title: 'Terraform',
                description: 'Infrastructure as Code, state management, and automation',
                category: 'technologies',
                subcategory: 'Infrastructure as Code',
                icon: '🏗️',
                tags: ['infrastructure', 'terraform', 'iac', 'automation'],
                type: 'technology'
            },
            {
                id: 'security',
                title: 'Security',
                description: 'HTTPS, CSP headers, authentication, and best practices',
                category: 'technologies',
                subcategory: 'Security',
                icon: '🔒',
                tags: ['security', 'https', 'authentication', 'csp'],
                type: 'technology'
            },
            {
                id: 'cicd',
                title: 'CI/CD',
                description: 'GitHub Actions, automated deployment, and testing',
                category: 'technologies',
                subcategory: 'DevOps & Automation',
                icon: '🔄',
                tags: ['devops', 'cicd', 'github-actions', 'automation'],
                type: 'technology'
            },
            {
                id: 'monitoring',
                title: 'Monitoring',
                description: 'Analytics, performance tracking, and observability',
                category: 'technologies',
                subcategory: 'DevOps & Automation',
                icon: '📊',
                tags: ['monitoring', 'analytics', 'performance', 'observability'],
                type: 'technology'
            },
            {
                id: 'cost-optimization',
                title: 'Cost Optimization',
                description: 'Resource optimization, monitoring, and cost-effective solutions',
                category: 'technologies',
                subcategory: 'DevOps & Automation',
                icon: '💰',
                tags: ['cost-optimization', 'monitoring', 'efficiency'],
                type: 'technology'
            },
            {
                id: 'github-copilot',
                title: 'GitHub Copilot',
                description: 'AI-powered code suggestions, automated code review, and intelligent development assistance',
                category: 'technologies',
                subcategory: 'AI & Code Intelligence',
                icon: '🤖',
                tags: ['ai', 'copilot', 'code-assistance', 'automation'],
                type: 'technology'
            },
            {
                id: 'automated-code-review',
                title: 'Automated Code Review',
                description: 'Security scanning, performance analysis, accessibility checks, and quality validation',
                category: 'technologies',
                subcategory: 'AI & Code Intelligence',
                icon: '🔍',
                tags: ['ai', 'code-review', 'security-scanning', 'quality'],
                type: 'technology'
            },
            {
                id: 'best-practices',
                title: 'Best Practices',
                description: 'Comprehensive web development guidelines, security standards, and performance optimization',
                category: 'technologies',
                subcategory: 'AI & Code Intelligence',
                icon: '📋',
                tags: ['best-practices', 'guidelines', 'standards'],
                type: 'technology'
            },
            {
                id: 'plex-recommendations',
                title: 'Plex Movie Recommendations',
                description: 'AI-powered movie recommendation system using Plex watch history, TMDB API, and AWS Lambda',
                category: 'technologies',
                subcategory: 'AI & Machine Learning',
                icon: '🎬',
                tags: ['ai', 'recommendations', 'plex', 'tmdb', 'aws-lambda', 'machine-learning'],
                type: 'technology'
            },

            // Methodology Topics
            {
                id: 'hands-on-learning',
                title: 'Hands-on Learning',
                description: 'Learning by doing, building real projects, and solving actual problems',
                category: 'methodologies',
                subcategory: 'Learning Approach',
                icon: '🎯',
                tags: ['learning', 'practical', 'projects', 'problem-solving'],
                type: 'methodology'
            },
            {
                id: 'documentation-driven',
                title: 'Documentation-Driven',
                description: 'Comprehensive documentation of processes, decisions, and lessons learned',
                category: 'methodologies',
                subcategory: 'Learning Approach',
                icon: '📚',
                tags: ['documentation', 'knowledge-base', 'processes'],
                type: 'methodology'
            },
            {
                id: 'iterative-improvement',
                title: 'Iterative Improvement',
                description: 'Continuous refinement through feedback, testing, and optimization',
                category: 'methodologies',
                subcategory: 'Learning Approach',
                icon: '🔄',
                tags: ['improvement', 'feedback', 'testing', 'optimization'],
                type: 'methodology'
            },
            {
                id: 'community-learning',
                title: 'Community Learning',
                description: 'Engaging with the developer community, sharing knowledge, and learning from others',
                category: 'methodologies',
                subcategory: 'Learning Approach',
                icon: '🤝',
                tags: ['community', 'collaboration', 'knowledge-sharing'],
                type: 'methodology'
            },

            // Feature Topics
            {
                id: 'ai-powered-development',
                title: 'AI-Powered Development',
                description: 'GitHub Copilot integration with intelligent code suggestions and automated review',
                category: 'features',
                subcategory: 'AI Integration',
                icon: '🤖',
                tags: ['ai', 'copilot', 'automation', 'development'],
                type: 'feature'
            },
            {
                id: 'security-headers',
                title: 'Advanced Security Headers',
                description: 'Comprehensive security headers including CSP, XSS protection, and frame options',
                category: 'features',
                subcategory: 'Security',
                icon: '🛡️',
                tags: ['security', 'headers', 'csp', 'xss-protection'],
                type: 'feature'
            },
            {
                id: 'vulnerability-scanning',
                title: 'Vulnerability Scanning',
                description: 'Automated vulnerability scanning with dependency analysis and security assessment',
                category: 'features',
                subcategory: 'Security',
                icon: '🔍',
                tags: ['security', 'vulnerability-scanning', 'dependency-analysis'],
                type: 'feature'
            },
            {
                id: 'workflow-optimization',
                title: 'CI/CD Workflow Optimization',
                description: 'Reduced workflows from 7 to 4 by removing redundancies and optimizing triggers',
                category: 'features',
                subcategory: 'DevOps',
                icon: '🚀',
                tags: ['cicd', 'optimization', 'workflows', 'automation'],
                type: 'feature'
            },
            {
                id: 'performance-optimization',
                title: 'Core Web Vitals Optimization',
                description: 'Optimized for Core Web Vitals including LCP, FID, and CLS with performance monitoring',
                category: 'features',
                subcategory: 'Performance',
                icon: '⚡',
                tags: ['performance', 'core-web-vitals', 'lcp', 'fid', 'cls'],
                type: 'feature'
            },
            {
                id: 'state-management',
                title: 'Terraform State Management',
                description: 'Comprehensive state management with drift detection, remote backend, and validation',
                category: 'features',
                subcategory: 'Infrastructure',
                icon: '🏗️',
                tags: ['terraform', 'state-management', 'drift-detection'],
                type: 'feature'
            },
            {
                id: 'cloudwatch-dashboards',
                title: 'CloudWatch Dashboards',
                description: 'Comprehensive monitoring dashboards for cost tracking, service health, and performance',
                category: 'features',
                subcategory: 'Monitoring',
                icon: '📊',
                tags: ['monitoring', 'cloudwatch', 'dashboards', 'cost-tracking'],
                type: 'feature'
            },

            // Lesson Topics
            {
                id: 'security-first',
                title: 'Security First',
                description: 'Authentication is critical - client-side auth is easily bypassed, server-side validation is essential',
                category: 'lessons',
                subcategory: 'Security',
                icon: '🔒',
                tags: ['security', 'authentication', 'server-side', 'validation'],
                type: 'lesson'
            },
            {
                id: 'performance-matters',
                title: 'Performance Matters',
                description: 'Performance optimization should be considered from the beginning, not as an afterthought',
                category: 'lessons',
                subcategory: 'Performance',
                icon: '⚡',
                tags: ['performance', 'optimization', 'early-consideration'],
                type: 'lesson'
            },
            {
                id: 'infrastructure-as-code',
                title: 'Infrastructure as Code',
                description: 'Terraform enables consistent, repeatable infrastructure deployments across environments',
                category: 'lessons',
                subcategory: 'Infrastructure',
                icon: '🏗️',
                tags: ['infrastructure', 'terraform', 'reproducible', 'deployments'],
                type: 'lesson'
            },
            {
                id: 'monitoring-analytics',
                title: 'Monitoring & Analytics',
                description: 'Analytics and monitoring provide valuable insights for optimization and user experience',
                category: 'lessons',
                subcategory: 'Monitoring',
                icon: '📊',
                tags: ['monitoring', 'analytics', 'insights', 'optimization'],
                type: 'lesson'
            },
            {
                id: 'ai-powered-development-lesson',
                title: 'AI-Powered Development',
                description: 'GitHub Copilot provides context-aware code suggestions that accelerate development while maintaining quality',
                category: 'lessons',
                subcategory: 'AI & Development',
                icon: '🤖',
                tags: ['ai', 'copilot', 'code-suggestions', 'development'],
                type: 'lesson'
            },
            {
                id: 'workflow-management',
                title: 'CI/CD & Workflow Management',
                description: 'Reducing workflow complexity by consolidating similar processes improves maintainability',
                category: 'lessons',
                subcategory: 'DevOps',
                icon: '🔄',
                tags: ['cicd', 'workflows', 'maintainability', 'consolidation'],
                type: 'lesson'
            },
            {
                id: 'state-drift',
                title: 'State Drift is Inevitable',
                description: 'Infrastructure can drift from Terraform state due to manual changes, API updates, or external modifications',
                category: 'lessons',
                subcategory: 'Infrastructure',
                icon: '🏗️',
                tags: ['terraform', 'state-drift', 'infrastructure', 'monitoring'],
                type: 'lesson'
            },
            {
                id: 'repository-health',
                title: 'Repository Health & Maintenance',
                description: 'Network storage can cause git corruption issues. Regular repository maintenance is essential',
                category: 'lessons',
                subcategory: 'Development',
                icon: '🔧',
                tags: ['git', 'repository', 'maintenance', 'corruption'],
                type: 'lesson'
            },
            {
                id: 'plex-recommendations-lessons',
                title: 'Plex Recommendations Project Lessons',
                description: 'Building a complete AI recommendation system taught valuable lessons about API integration, cost optimization, and repository management',
                category: 'lessons',
                subcategory: 'AI & Development',
                icon: '🎬',
                tags: ['ai', 'recommendations', 'api-integration', 'cost-optimization', 'repository-management'],
                type: 'lesson'
            },

            // Future Goals
            {
                id: 'advanced-cloud-services',
                title: 'Advanced Cloud Services',
                description: 'Exploring advanced AWS services like Lambda, API Gateway, and serverless architectures',
                category: 'future',
                subcategory: 'Cloud Development',
                icon: '🚀',
                tags: ['aws', 'lambda', 'api-gateway', 'serverless'],
                type: 'future-goal'
            },
            {
                id: 'security-specialization',
                title: 'Security Specialization',
                description: 'Deepening security knowledge with advanced threat detection, penetration testing, and compliance',
                category: 'future',
                subcategory: 'Security',
                icon: '🔐',
                tags: ['security', 'threat-detection', 'penetration-testing', 'compliance'],
                type: 'future-goal'
            },
            {
                id: 'mobile-development',
                title: 'Mobile Development',
                description: 'Expanding into mobile app development with React Native or Flutter for cross-platform solutions',
                category: 'future',
                subcategory: 'Mobile Development',
                icon: '📱',
                tags: ['mobile', 'react-native', 'flutter', 'cross-platform'],
                type: 'future-goal'
            },
            {
                id: 'advanced-ai-ml',
                title: 'Advanced AI/ML Integration',
                description: 'Expanding AI capabilities with advanced machine learning models and natural language processing',
                category: 'future',
                subcategory: 'AI & Machine Learning',
                icon: '🤖',
                tags: ['ai', 'machine-learning', 'nlp', 'automation'],
                type: 'future-goal'
            },
            {
                id: 'advanced-code-intelligence',
                title: 'Advanced Code Intelligence',
                description: 'Exploring advanced code analysis, automated testing, and intelligent debugging with AI-powered tools',
                category: 'future',
                subcategory: 'AI & Development',
                icon: '🔍',
                tags: ['ai', 'code-analysis', 'automated-testing', 'debugging'],
                type: 'future-goal'
            },
            {
                id: 'advanced-infrastructure',
                title: 'Advanced Infrastructure Management',
                description: 'Deepening knowledge of Terraform advanced features, multi-cloud strategies, and enterprise-scale automation',
                category: 'future',
                subcategory: 'Infrastructure',
                icon: '🏗️',
                tags: ['terraform', 'multi-cloud', 'enterprise', 'automation'],
                type: 'future-goal'
            },
            {
                id: 'advanced-observability',
                title: 'Advanced Observability',
                description: 'Exploring advanced monitoring with Prometheus, Grafana, distributed tracing, and comprehensive platforms',
                category: 'future',
                subcategory: 'Monitoring',
                icon: '📊',
                tags: ['monitoring', 'prometheus', 'grafana', 'distributed-tracing'],
                type: 'future-goal'
            },
            
            // New Topics from Today's Work (October 11, 2025)
            {
                id: 'security-scanning',
                title: 'Automated Security Scanning',
                description: 'Comprehensive security scanning for code, infrastructure, and dependencies with false positive handling',
                category: 'technologies',
                subcategory: 'Security & Compliance',
                icon: '🔍',
                tags: ['security', 'scanning', 'automation', 'devsecops', 'vulnerability-detection'],
                type: 'technology'
            },
            {
                id: 'github-actions-security',
                title: 'GitHub Actions Security Workflows',
                description: 'Implementing security validation in CI/CD pipelines with automated scanning and robust error handling',
                category: 'methodologies',
                subcategory: 'CI/CD Security',
                icon: '🛡️',
                tags: ['github-actions', 'security', 'ci-cd', 'automation', 'workflows'],
                type: 'methodology'
            },
            {
                id: 'security-headers',
                title: 'HTTP Security Headers',
                description: 'Implementing comprehensive security headers (CSP, XSS protection, content type validation)',
                category: 'technologies',
                subcategory: 'Web Security',
                icon: '🔒',
                tags: ['security-headers', 'csp', 'xss-protection', 'web-security', 'http'],
                type: 'technology'
            },
            {
                id: 'false-positive-handling',
                title: 'Security Scan False Positive Management',
                description: 'Developing robust logic to handle security scan false positives and improve scanning accuracy',
                category: 'methodologies',
                subcategory: 'Security Operations',
                icon: '🎯',
                tags: ['false-positives', 'security-scanning', 'accuracy', 'automation', 'quality-assurance'],
                type: 'methodology'
            },
            {
                id: 'gitignore-patterns',
                title: 'Advanced Gitignore Patterns',
                description: 'Managing generated files and reports with comprehensive gitignore patterns for clean repositories',
                category: 'methodologies',
                subcategory: 'Version Control',
                icon: '📁',
                tags: ['git', 'gitignore', 'version-control', 'file-management', 'patterns'],
                type: 'methodology'
            },
            {
                id: 'bash-script-robustness',
                title: 'Robust Bash Scripting',
                description: 'Writing reliable bash scripts with proper error handling, exit code management, and variable checking',
                category: 'technologies',
                subcategory: 'Scripting & Automation',
                icon: '🐚',
                tags: ['bash', 'scripting', 'error-handling', 'automation', 'reliability'],
                type: 'technology'
            },
            {
                id: 'production-cleanup',
                title: 'Production Environment Cleanup',
                description: 'Removing test and debug files from production deployments while preserving essential functionality',
                category: 'methodologies',
                subcategory: 'Deployment Management',
                icon: '🧹',
                tags: ['production', 'cleanup', 'deployment', 'testing', 'maintenance'],
                type: 'methodology'
            },
            {
                id: 'dashboard-security-integration',
                title: 'Security Metrics Dashboard Integration',
                description: 'Integrating real-time security scanning results into monitoring dashboards for comprehensive visibility',
                category: 'features',
                subcategory: 'Dashboard Features',
                icon: '📊',
                tags: ['dashboard', 'security', 'metrics', 'monitoring', 'integration'],
                type: 'feature'
            }
        ];

        this.filteredTopics = [...this.topics];
    }

    setupEventListeners() {
        // Search functionality
        const searchInput = document.getElementById('topic-search');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.searchTerm = e.target.value.toLowerCase();
                this.filterTopics();
            });
        }

        // Filter tabs
        const filterTabs = document.querySelectorAll('.filter-tab');
        filterTabs.forEach(tab => {
            tab.addEventListener('click', (e) => {
                // Update active tab
                filterTabs.forEach(t => t.classList.remove('active'));
                e.target.classList.add('active');
                
                // Update filter
                this.currentFilter = e.target.dataset.filter;
                this.filterTopics();
            });
        });
    }

    filterTopics() {
        this.filteredTopics = this.topics.filter(topic => {
            // Category filter
            const categoryMatch = this.currentFilter === 'all' || topic.category === this.currentFilter;
            
            // Search filter
            const searchMatch = !this.searchTerm || 
                topic.title.toLowerCase().includes(this.searchTerm) ||
                topic.description.toLowerCase().includes(this.searchTerm) ||
                topic.tags.some(tag => tag.toLowerCase().includes(this.searchTerm));
            
            return categoryMatch && searchMatch;
        });

        this.renderTopics();
        this.updateStats();
    }

    renderTopics() {
        const topicsGrid = document.getElementById('topics-grid');
        if (!topicsGrid) return;

        if (this.filteredTopics.length === 0) {
            topicsGrid.innerHTML = `
                <div class="no-results">
                    <div class="no-results-icon">🔍</div>
                    <h3>No topics found</h3>
                    <p>Try adjusting your search terms or filter selection</p>
                </div>
            `;
            return;
        }

        topicsGrid.innerHTML = this.filteredTopics.map(topic => this.createTopicCard(topic)).join('');
    }

    createTopicCard(topic) {
        const categoryColors = {
            technologies: '#3b82f6',
            methodologies: '#10b981',
            features: '#f59e0b',
            lessons: '#ef4444',
            future: '#8b5cf6'
        };

        const categoryColor = categoryColors[topic.category] || '#6b7280';

        return `
            <div class="topic-card" data-category="${topic.category}" data-tags="${topic.tags.join(',')}">
                <div class="topic-header" style="border-left-color: ${categoryColor}">
                    <div class="topic-icon">${topic.icon}</div>
                    <div class="topic-meta">
                        <span class="topic-category" style="background-color: ${categoryColor}20; color: ${categoryColor}">
                            ${this.capitalizeFirst(topic.category)}
                        </span>
                        <span class="topic-subcategory">${topic.subcategory}</span>
                    </div>
                </div>
                <div class="topic-content">
                    <h3>${topic.title}</h3>
                    <p>${topic.description}</p>
                    <div class="topic-tags">
                        ${topic.tags.map(tag => `<span class="tag">${tag.replace('-', ' ')}</span>`).join('')}
                    </div>
                </div>
                <div class="topic-footer">
                    <span class="topic-type">${topic.type.replace('-', ' ')}</span>
                </div>
            </div>
        `;
    }

    updateStats() {
        const totalTopics = document.getElementById('total-topics');
        const filteredTopics = document.getElementById('filtered-topics');
        
        if (totalTopics) totalTopics.textContent = this.topics.length;
        if (filteredTopics) filteredTopics.textContent = this.filteredTopics.length;
    }

    capitalizeFirst(str) {
        return str.charAt(0).toUpperCase() + str.slice(1);
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new LearningTopics();
});
