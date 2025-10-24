// Simple Learning Topics JavaScript
document.addEventListener('DOMContentLoaded', function() {
  console.log('Learning topics script loaded');

  const topics = [
    // Frontend Technologies
    {
      id: 'html5-semantic',
      title: 'HTML5 Semantic Elements',
      description: 'Article, section, nav, header, footer, aside, and accessibility',
      category: 'frontend',
      icon: '📄',
      tags: ['html5', 'semantic', 'accessibility', 'seo'],
      difficulty: 'Beginner',
      subtopics: ['Semantic markup', 'ARIA attributes', 'Screen readers', 'SEO optimization']
    },
    {
      id: 'css-grid',
      title: 'CSS Grid Layout',
      description: 'Two-dimensional layout system for complex web layouts',
      category: 'frontend',
      icon: '📐',
      tags: ['css', 'grid', 'layout', 'responsive'],
      difficulty: 'Intermediate',
      subtopics: ['Grid containers', 'Grid items', 'Grid areas', 'Responsive grids']
    },
    {
      id: 'css-flexbox',
      title: 'CSS Flexbox',
      description: 'One-dimensional layout method for flexible components',
      category: 'frontend',
      icon: '🔧',
      tags: ['css', 'flexbox', 'layout', 'alignment'],
      difficulty: 'Beginner',
      subtopics: ['Flex containers', 'Flex items', 'Alignment', 'Justification']
    },
    {
      id: 'javascript-es6',
      title: 'JavaScript ES6+ Features',
      description: 'Arrow functions, destructuring, modules, async/await',
      category: 'frontend',
      icon: '⚡',
      tags: ['javascript', 'es6', 'modern-js', 'async'],
      difficulty: 'Intermediate',
      subtopics: ['Arrow functions', 'Destructuring', 'Modules', 'Async/await', 'Promises']
    },
    {
      id: 'react-basics',
      title: 'React Fundamentals',
      description: 'Components, props, state, hooks, and lifecycle',
      category: 'frontend',
      icon: '⚛️',
      tags: ['react', 'components', 'hooks', 'state'],
      difficulty: 'Intermediate',
      subtopics: ['Components', 'Props', 'State', 'Hooks', 'Lifecycle']
    },
    {
      id: 'vue-basics',
      title: 'Vue.js Fundamentals',
      description: 'Template syntax, directives, components, and reactivity',
      category: 'frontend',
      icon: '💚',
      tags: ['vue', 'components', 'directives', 'reactivity'],
      difficulty: 'Intermediate',
      subtopics: ['Template syntax', 'Directives', 'Components', 'Reactivity', 'Composition API']
    },

    // Backend Technologies
    {
      id: 'nodejs-express',
      title: 'Node.js & Express',
      description: 'Server-side JavaScript, routing, middleware, and APIs',
      category: 'backend',
      icon: '🟢',
      tags: ['nodejs', 'express', 'api', 'server'],
      difficulty: 'Intermediate',
      subtopics: ['Express routing', 'Middleware', 'REST APIs', 'Error handling']
    },
    {
      id: 'python-django',
      title: 'Django Framework',
      description: 'Python web framework, models, views, templates',
      category: 'backend',
      icon: '🐍',
      tags: ['python', 'django', 'mvc', 'orm'],
      difficulty: 'Intermediate',
      subtopics: ['Models', 'Views', 'Templates', 'ORM', 'Admin interface']
    },
    {
      id: 'database-design',
      title: 'Database Design',
      description: 'Relational databases, normalization, indexing, queries',
      category: 'backend',
      icon: '🗄️',
      tags: ['database', 'sql', 'normalization', 'indexing'],
      difficulty: 'Intermediate',
      subtopics: ['ER diagrams', 'Normalization', 'Indexing', 'Query optimization', 'ACID properties']
    },
    {
      id: 'api-design',
      title: 'RESTful API Design',
      description: 'HTTP methods, status codes, versioning, documentation',
      category: 'backend',
      icon: '🔌',
      tags: ['api', 'rest', 'http', 'documentation'],
      difficulty: 'Intermediate',
      subtopics: ['HTTP methods', 'Status codes', 'Versioning', 'Documentation', 'Authentication']
    },

    // Cloud & Infrastructure
    {
      id: 'aws-compute',
      title: 'AWS Compute Services',
      description: 'EC2, Lambda, ECS, EKS, and serverless computing',
      category: 'cloud',
      icon: '🖥️',
      tags: ['aws', 'compute', 'ec2', 'lambda', 'serverless'],
      difficulty: 'Intermediate',
      subtopics: ['EC2 instances', 'Lambda functions', 'ECS containers', 'EKS Kubernetes', 'Serverless']
    },
    {
      id: 'aws-storage',
      title: 'AWS Storage Services',
      description: 'S3, EBS, EFS, Glacier, and data lifecycle management',
      category: 'cloud',
      icon: '💾',
      tags: ['aws', 'storage', 's3', 'ebs', 'lifecycle'],
      difficulty: 'Intermediate',
      subtopics: ['S3 buckets', 'EBS volumes', 'EFS file systems', 'Glacier archive', 'Lifecycle policies']
    },
    {
      id: 'aws-networking',
      title: 'AWS Networking',
      description: 'VPC, subnets, security groups, load balancers, Route 53',
      category: 'cloud',
      icon: '🌐',
      tags: ['aws', 'networking', 'vpc', 'security-groups', 'dns'],
      difficulty: 'Advanced',
      subtopics: ['VPC design', 'Subnets', 'Security groups', 'Load balancers', 'DNS routing']
    },
    {
      id: 'terraform-basics',
      title: 'Terraform Fundamentals',
      description: 'Infrastructure as Code, providers, resources, state management',
      category: 'infrastructure',
      icon: '🏗️',
      tags: ['terraform', 'iac', 'infrastructure', 'automation'],
      difficulty: 'Intermediate',
      subtopics: ['Providers', 'Resources', 'State management', 'Modules', 'Workspaces']
    },
    {
      id: 'terraform-modules',
      title: 'Terraform Modules',
      description: 'Reusable components, variable design, output patterns',
      category: 'infrastructure',
      icon: '🧩',
      tags: ['terraform', 'modules', 'reusability', 'design-patterns'],
      difficulty: 'Advanced',
      subtopics: ['Module design', 'Variable patterns', 'Output patterns', 'Module composition', 'Versioning']
    },
    {
      id: 'kubernetes-basics',
      title: 'Kubernetes Fundamentals',
      description: 'Pods, services, deployments, namespaces, and cluster management',
      category: 'infrastructure',
      icon: '☸️',
      tags: ['kubernetes', 'containers', 'orchestration', 'pods'],
      difficulty: 'Advanced',
      subtopics: ['Pods', 'Services', 'Deployments', 'Namespaces', 'ConfigMaps', 'Secrets']
    },
    {
      id: 'docker-containers',
      title: 'Docker & Containers',
      description: 'Containerization, images, Dockerfile, multi-stage builds',
      category: 'infrastructure',
      icon: '🐳',
      tags: ['docker', 'containers', 'images', 'dockerfile'],
      difficulty: 'Intermediate',
      subtopics: ['Docker images', 'Dockerfile', 'Multi-stage builds', 'Container registry', 'Best practices']
    },

    // DevOps & CI/CD
    {
      id: 'github-actions',
      title: 'GitHub Actions',
      description: 'CI/CD workflows, automation, secrets, and deployment',
      category: 'devops',
      icon: '🔄',
      tags: ['github', 'actions', 'cicd', 'automation'],
      difficulty: 'Intermediate',
      subtopics: ['Workflows', 'Triggers', 'Secrets', 'Artifacts', 'Deployment']
    },
    {
      id: 'jenkins-pipeline',
      title: 'Jenkins Pipelines',
      description: 'Declarative pipelines, stages, agents, and automation',
      category: 'devops',
      icon: '🔧',
      tags: ['jenkins', 'pipeline', 'automation', 'stages'],
      difficulty: 'Advanced',
      subtopics: ['Declarative syntax', 'Pipeline stages', 'Agent configuration', 'Shared libraries', 'Blue Ocean']
    },
    {
      id: 'gitops-argocd',
      title: 'GitOps with ArgoCD',
      description: 'Git-based deployment, continuous delivery, and automation',
      category: 'devops',
      icon: '🚀',
      tags: ['gitops', 'argocd', 'deployment', 'automation'],
      difficulty: 'Advanced',
      subtopics: ['GitOps principles', 'ArgoCD setup', 'Application management', 'Sync policies', 'Rollbacks']
    },
    {
      id: 'monitoring-observability',
      title: 'Monitoring & Observability',
      description: 'Prometheus, Grafana, logging, metrics, and alerting',
      category: 'devops',
      icon: '📊',
      tags: ['monitoring', 'observability', 'prometheus', 'grafana'],
      difficulty: 'Advanced',
      subtopics: ['Metrics collection', 'Log aggregation', 'Alerting', 'Dashboards', 'SLI/SLO']
    },

    // Security
    {
      id: 'web-security',
      title: 'Web Application Security',
      description: 'OWASP Top 10, XSS, CSRF, SQL injection, and secure coding',
      category: 'security',
      icon: '🛡️',
      tags: ['security', 'owasp', 'xss', 'csrf', 'injection'],
      difficulty: 'Advanced',
      subtopics: ['OWASP Top 10', 'XSS prevention', 'CSRF protection', 'SQL injection', 'Secure headers']
    },
    {
      id: 'cloud-security',
      title: 'Cloud Security',
      description: 'IAM, encryption, network security, and compliance',
      category: 'security',
      icon: '🔐',
      tags: ['cloud', 'security', 'iam', 'encryption', 'compliance'],
      difficulty: 'Advanced',
      subtopics: ['Identity management', 'Access control', 'Encryption', 'Network security', 'Compliance']
    },
    {
      id: 'devsecops',
      title: 'DevSecOps',
      description: 'Security in CI/CD, SAST, DAST, and security automation',
      category: 'security',
      icon: '🔒',
      tags: ['devsecops', 'security', 'sast', 'dast', 'automation'],
      difficulty: 'Advanced',
      subtopics: ['Security scanning', 'SAST/DAST', 'Dependency scanning', 'Security gates', 'Automation']
    },
    {
      id: 'kubernetes-security',
      title: 'Kubernetes Security',
      description: 'RBAC, network policies, pod security, and cluster hardening',
      category: 'security',
      icon: '☸️',
      tags: ['kubernetes', 'security', 'rbac', 'network-policies'],
      difficulty: 'Advanced',
      subtopics: ['RBAC', 'Network policies', 'Pod security standards', 'Secrets management', 'Cluster hardening']
    },

    // Data & Analytics
    {
      id: 'data-pipelines',
      title: 'Data Pipelines',
      description: 'ETL processes, data transformation, and workflow orchestration',
      category: 'data',
      icon: '📈',
      tags: ['data', 'etl', 'pipelines', 'transformation'],
      difficulty: 'Advanced',
      subtopics: ['ETL design', 'Data transformation', 'Workflow orchestration', 'Data quality', 'Monitoring']
    },
    {
      id: 'sql-optimization',
      title: 'SQL Performance',
      description: 'Query optimization, indexing, execution plans, and tuning',
      category: 'data',
      icon: '⚡',
      tags: ['sql', 'performance', 'optimization', 'indexing'],
      difficulty: 'Advanced',
      subtopics: ['Query optimization', 'Index design', 'Execution plans', 'Performance tuning', 'Monitoring']
    },
    {
      id: 'machine-learning',
      title: 'Machine Learning',
      description: 'ML algorithms, model training, deployment, and MLOps',
      category: 'data',
      icon: '🤖',
      tags: ['ml', 'ai', 'algorithms', 'deployment', 'mlops'],
      difficulty: 'Advanced',
      subtopics: ['Algorithm selection', 'Model training', 'Feature engineering', 'Model deployment', 'MLOps']
    },

    // Specialized Topics
    {
      id: 'microservices',
      title: 'Microservices Architecture',
      description: 'Service design, communication, patterns, and best practices',
      category: 'architecture',
      icon: '🔗',
      tags: ['microservices', 'architecture', 'services', 'communication'],
      difficulty: 'Advanced',
      subtopics: ['Service design', 'API communication', 'Data consistency', 'Service discovery', 'Circuit breakers']
    },
    {
      id: 'event-driven',
      title: 'Event-Driven Architecture',
      description: 'Event streaming, message queues, and asynchronous patterns',
      category: 'architecture',
      icon: '📡',
      tags: ['events', 'messaging', 'async', 'streaming'],
      difficulty: 'Advanced',
      subtopics: ['Event sourcing', 'Message queues', 'Event streaming', 'Async patterns', 'CQRS']
    },
    {
      id: 'performance-optimization',
      title: 'Performance Optimization',
      description: 'Caching, CDN, database tuning, and application optimization',
      category: 'performance',
      icon: '⚡',
      tags: ['performance', 'caching', 'optimization', 'cdn'],
      difficulty: 'Advanced',
      subtopics: ['Caching strategies', 'CDN optimization', 'Database tuning', 'Application profiling', 'Load testing']
    }
  ];

  let filteredTopics = topics;
  let currentFilter = 'all';

  function renderTopics() {
    const grid = document.getElementById('topics-grid');
    if (!grid) {
      console.log('Grid not found');
      return;
    }

    grid.innerHTML = '';

    filteredTopics.forEach(topic => {
      const card = document.createElement('div');
      card.className = 'topic-card';
      card.innerHTML = `
                <div class="topic-card-header">
                    <span class="topic-icon">${topic.icon}</span>
                    <div class="topic-meta">
                        <span class="topic-category">${topic.category.toUpperCase()}</span>
                        <span class="topic-difficulty difficulty-${topic.difficulty.toLowerCase()}">${topic.difficulty}</span>
                    </div>
                </div>
                <div class="topic-card-content">
                    <h3>${topic.title}</h3>
                    <p>${topic.description}</p>
                    <div class="topic-subtopics">
                        <h4>Key Areas:</h4>
                        <ul>
                            ${topic.subtopics.map(subtopic => `<li>${subtopic}</li>`).join('')}
                        </ul>
                    </div>
                    <div class="topic-tags">
                        ${topic.tags.map(tag => `<span class="topic-tag">${tag}</span>`).join('')}
                    </div>
                </div>
            `;
      grid.appendChild(card);
    });

    updateStats();
  }

  function updateStats() {
    const statsElement = document.getElementById('topic-count');
    if (statsElement) {
      statsElement.textContent = `Showing ${filteredTopics.length} of ${topics.length} topics`;
    }
  }

  function filterTopics() {
    const searchInput = document.getElementById('topic-search');
    const searchTerm = searchInput ? searchInput.value.toLowerCase() : '';

    filteredTopics = topics.filter(topic => {
      const matchesSearch = topic.title.toLowerCase().includes(searchTerm) ||
                                 topic.description.toLowerCase().includes(searchTerm) ||
                                 topic.tags.some(tag => tag.toLowerCase().includes(searchTerm));

      const matchesFilter = currentFilter === 'all' || topic.category === currentFilter;

      return matchesSearch && matchesFilter;
    });

    renderTopics();
  }

  // Setup event listeners
  const searchInput = document.getElementById('topic-search');
  if (searchInput) {
    searchInput.addEventListener('input', filterTopics);
  }

  const filterButtons = document.querySelectorAll('.filter-btn');
  filterButtons.forEach(btn => {
    btn.addEventListener('click', function() {
      // Remove active class from all buttons
      filterButtons.forEach(b => b.classList.remove('active'));
      // Add active class to clicked button
      this.classList.add('active');

      currentFilter = this.dataset.filter;
      filterTopics();
    });
  });

  // Initial render
  renderTopics();
});
