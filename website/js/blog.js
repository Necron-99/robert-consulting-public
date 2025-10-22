// Blog Management System
class BlogManager {
    constructor() {
        this.posts = [];
        this.currentFilter = 'all';
        this.currentPage = 1;
        this.postsPerPage = 6;
        this.init();
    }

    init() {
        this.loadPosts();
        this.setupEventListeners();
        this.renderPosts();
    }

    loadPosts() {
        // Blog posts data - this would typically come from a CMS or API
        this.posts = [
            {
                id: 1,
                title: "AWS Lambda Cold Start Optimization: From 3 Seconds to 200ms",
                excerpt: "Learn proven strategies to eliminate AWS Lambda cold starts and achieve sub-200ms response times. Includes connection pooling, provisioned concurrency, and memory optimization techniques.",
                content: "blog-posts/aws-lambda-cold-start-optimization.html",
                date: "2025-10-13",
                category: "aws",
                tags: ["AWS Lambda", "Performance", "Optimization", "Cold Start", "Connection Pooling", "Serverless"],
                icon: "⚡",
                readTime: "7 min read"
            },
            {
                id: 2,
                title: "Terraform Module Design Patterns: Building Reusable Infrastructure Components",
                excerpt: "Master Terraform module design with proven patterns for reusability, maintainability, and scalability. Learn best practices for variable design, output patterns, and module composition.",
                content: "blog-posts/terraform-module-design-patterns.html",
                date: "2025-10-14",
                category: "terraform",
                tags: ["Terraform", "Infrastructure as Code", "Module Design", "Best Practices", "Reusable Components", "IaC Patterns"],
                icon: "🏗️",
                readTime: "12 min read"
            },
            {
                id: 3,
                title: "GitOps with GitHub Actions: Automating Terraform Deployments",
                excerpt: "Learn how to implement GitOps workflows using GitHub Actions to automate Terraform deployments with proper approval gates, security scanning, and rollback capabilities.",
                content: "blog-posts/gitops-github-actions-terraform.html",
                date: "2025-10-15",
                category: "cicd",
                tags: ["GitOps", "GitHub Actions", "Terraform", "Automation", "Deployment", "CI/CD"],
                icon: "🚀",
                readTime: "9 min read"
            },
            {
                id: 4,
                title: "DevSecOps Security Scanning: Building a Comprehensive Pipeline",
                excerpt: "Learn how to implement comprehensive security scanning in your DevSecOps pipeline with SAST, DAST, dependency scanning, and infrastructure security checks using modern tools.",
                content: "blog-posts/devsecops-security-scanning-pipeline.html",
                date: "2025-10-16",
                category: "security",
                tags: ["DevSecOps", "Security Scanning", "SAST", "DAST", "Dependency Scanning", "Infrastructure Security"],
                icon: "🔒",
                readTime: "10 min read"
            },
            {
                id: 5,
                title: "Database DevOps: Automating SQL Server Deployments with CI/CD",
                excerpt: "Learn how to integrate database changes into your CI/CD pipeline with automated schema migrations, data validation, and rollback procedures for SQL Server environments.",
                content: "blog-posts/database-devops-sql-server-automation.html",
                date: "2025-10-17",
                category: "devops",
                tags: ["Database DevOps", "SQL Server", "CI/CD", "Schema Migration", "Automation", "Deployment"],
                icon: "🗄️",
                readTime: "11 min read"
            },
            {
                id: 6,
                title: "AWS Well-Architected Framework: A Practical Implementation Guide",
                excerpt: "Apply the AWS Well-Architected Framework principles to design cost-effective, secure, and scalable cloud architectures. Learn practical implementation strategies for all five pillars.",
                content: "blog-posts/aws-well-architected-framework-implementation.html",
                date: "2025-10-20",
                category: "aws",
                tags: ["AWS Well-Architected", "Cloud Architecture", "Best Practices", "Scalability", "Cost Optimization", "Security"],
                icon: "🏛️",
                readTime: "14 min read"
            },
            {
                id: 7,
                title: "Terragrunt Best Practices: Enterprise Infrastructure as Code at Scale",
                excerpt: "Master Terragrunt for enterprise-scale Infrastructure as Code. Learn DRY principles, environment management, remote state configuration, and advanced patterns for large organizations.",
                content: "blog-posts/terragrunt-best-practices-enterprise-iac.html",
                date: "2025-10-21",
                category: "terraform",
                tags: ["Terragrunt", "Infrastructure as Code", "Terraform", "DRY Principles", "Enterprise IaC", "Best Practices"],
                icon: "🏗️",
                readTime: "13 min read"
            },
            {
                id: 8,
                title: "Kubernetes CI/CD with ArgoCD: GitOps for Container Orchestration",
                excerpt: "Learn how to implement GitOps workflows for Kubernetes using ArgoCD. Master automated deployments, rollbacks, and multi-environment management for containerized applications.",
                content: "blog-posts/kubernetes-cicd-argocd-gitops.html",
                date: "2025-10-22",
                category: "cicd",
                tags: ["Kubernetes", "ArgoCD", "GitOps", "CI/CD", "Container Orchestration", "Automated Deployment"],
                icon: "☸️",
                readTime: "11 min read"
            },
            {
                id: 4,
                title: "AWS Cost Optimization: 5 Strategies That Saved My Client $50K Annually",
                excerpt: "Learn how to implement intelligent caching, S3 lifecycle policies, and Lambda optimization to dramatically reduce AWS costs while maintaining performance.",
                content: "blog-posts/aws-cost-optimization.html",
                date: "2025-01-27",
                category: "aws",
                tags: ["AWS", "Cost Optimization", "S3", "Lambda", "CloudWatch"],
                icon: "💰",
                readTime: "8 min read"
            },
            {
                id: 2,
                title: "Terraform Best Practices: Building Scalable Infrastructure as Code",
                excerpt: "Discover essential Terraform patterns, module design principles, and state management strategies for enterprise-scale deployments.",
                content: "blog-posts/terraform-best-practices.html",
                date: "2025-01-26",
                category: "terraform",
                tags: ["Terraform", "Infrastructure as Code", "Modules", "State Management", "Best Practices"],
                icon: "🏗️",
                readTime: "12 min read"
            },
            {
                id: 3,
                title: "CI/CD Pipeline Security: Implementing DevSecOps from Day One",
                excerpt: "Build secure CI/CD pipelines with automated security scanning, secret management, and compliance checks integrated into your development workflow.",
                content: "blog-posts/cicd-security.html",
                date: "2025-01-25",
                category: "security",
                tags: ["DevSecOps", "CI/CD", "Security Scanning", "Secrets Management", "Compliance"],
                icon: "🔒",
                readTime: "10 min read"
            },
            {
                id: 4,
                title: "AWS Lambda Performance Tuning: From 3 Seconds to 200ms",
                excerpt: "Optimize Lambda functions for maximum performance with proper memory allocation, connection pooling, and cold start mitigation strategies.",
                content: "blog-posts/lambda-optimization.html",
                date: "2025-01-24",
                category: "aws",
                tags: ["AWS Lambda", "Performance", "Optimization", "Cold Start", "Memory"],
                icon: "⚡",
                readTime: "7 min read"
            },
            {
                id: 5,
                title: "GitOps with GitHub Actions: Automating Infrastructure Deployments",
                excerpt: "Implement GitOps workflows using GitHub Actions to automate Terraform deployments with proper approval gates and rollback capabilities.",
                content: "blog-posts/gitops-github-actions.html",
                date: "2025-01-23",
                category: "cicd",
                tags: ["GitOps", "GitHub Actions", "Terraform", "Automation", "Deployment"],
                icon: "🚀",
                readTime: "9 min read"
            },
            {
                id: 6,
                title: "Database DevOps: Automating SQL Server Deployments with CI/CD",
                excerpt: "Integrate database changes into your CI/CD pipeline with automated schema migrations, data validation, and rollback procedures.",
                content: "blog-posts/database-devops.html",
                date: "2025-01-22",
                category: "devops",
                tags: ["Database DevOps", "SQL Server", "CI/CD", "Schema Migration", "Automation"],
                icon: "🗄️",
                readTime: "11 min read"
            },
            {
                id: 7,
                title: "AWS Security Best Practices: Building a Secure Cloud Foundation",
                excerpt: "Implement comprehensive security controls including IAM policies, VPC design, encryption, and monitoring for enterprise-grade AWS security.",
                content: "blog-posts/aws-security.html",
                date: "2025-01-21",
                category: "security",
                tags: ["AWS Security", "IAM", "VPC", "Encryption", "Monitoring"],
                icon: "🛡️",
                readTime: "13 min read"
            },
            {
                id: 8,
                title: "Terraform State Management: Avoiding the Pitfalls",
                excerpt: "Master Terraform state management with remote backends, state locking, and proper team collaboration workflows to prevent infrastructure conflicts.",
                content: "blog-posts/terraform-state.html",
                date: "2025-01-20",
                category: "terraform",
                tags: ["Terraform", "State Management", "Remote Backend", "Team Collaboration", "Best Practices"],
                icon: "📊",
                readTime: "10 min read"
            },
            {
                id: 9,
                title: "Monitoring and Observability: Building Production-Ready Systems",
                excerpt: "Implement comprehensive monitoring with CloudWatch, custom metrics, alerting, and distributed tracing for reliable production systems.",
                content: "blog-posts/monitoring-observability.html",
                date: "2025-01-19",
                category: "devops",
                tags: ["Monitoring", "Observability", "CloudWatch", "Alerting", "Production"],
                icon: "📈",
                readTime: "9 min read"
            },
            {
                id: 10,
                title: "AWS Well-Architected Framework: A Practical Implementation Guide",
                excerpt: "Apply the AWS Well-Architected Framework principles to design cost-effective, secure, and scalable cloud architectures for your organization.",
                content: "blog-posts/well-architected.html",
                date: "2025-01-18",
                category: "aws",
                tags: ["AWS Well-Architected", "Architecture", "Best Practices", "Scalability", "Cost Optimization"],
                icon: "🏛️",
                readTime: "14 min read"
            }
        ];
    }

    setupEventListeners() {
        // Filter buttons
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.setFilter(e.target.dataset.filter);
            });
        });
    }

    setFilter(filter) {
        this.currentFilter = filter;
        this.currentPage = 1;
        
        // Update active filter button
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.classList.remove('active');
        });
        document.querySelector(`[data-filter="${filter}"]`).classList.add('active');
        
        this.renderPosts();
    }

    getFilteredPosts() {
        if (this.currentFilter === 'all') {
            return this.posts;
        }
        return this.posts.filter(post => post.category === this.currentFilter);
    }

    getPaginatedPosts() {
        const filteredPosts = this.getFilteredPosts();
        const startIndex = (this.currentPage - 1) * this.postsPerPage;
        const endIndex = startIndex + this.postsPerPage;
        return filteredPosts.slice(startIndex, endIndex);
    }

    renderPosts() {
        const posts = this.getPaginatedPosts();
        const grid = document.getElementById('blog-grid');
        
        if (posts.length === 0) {
            grid.innerHTML = `
                <div style="grid-column: 1 / -1; text-align: center; padding: 40px;">
                    <h3>No posts found for this category</h3>
                    <p>Check back soon for new content!</p>
                </div>
            `;
            return;
        }

        grid.innerHTML = posts.map(post => this.createPostCard(post)).join('');
        this.renderPagination();
    }

    createPostCard(post) {
        const formattedDate = new Date(post.date).toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });

        return `
            <article class="blog-card" data-category="${post.category}">
                <div class="blog-card-image">
                    <span>${post.icon}</span>
                </div>
                <div class="blog-card-content">
                    <div class="blog-card-meta">
                        <div class="blog-card-date">
                            <span>📅</span>
                            <span>${formattedDate}</span>
                        </div>
                        <div class="blog-card-category">${post.category.toUpperCase()}</div>
                        <div class="blog-card-read-time">${post.readTime}</div>
                    </div>
                    <h3>${post.title}</h3>
                    <p>${post.excerpt}</p>
                    <div class="blog-card-tags">
                        ${post.tags.map(tag => `<span class="blog-tag">${tag}</span>`).join('')}
                    </div>
                    <a href="${post.content}" class="blog-card-link">Read More →</a>
                </div>
            </article>
        `;
    }

    renderPagination() {
        const filteredPosts = this.getFilteredPosts();
        const totalPages = Math.ceil(filteredPosts.length / this.postsPerPage);
        const pagination = document.getElementById('blog-pagination');
        
        if (totalPages <= 1) {
            pagination.innerHTML = '';
            return;
        }

        let paginationHTML = '';
        
        // Previous button
        if (this.currentPage > 1) {
            paginationHTML += `<button class="pagination-btn" onclick="blogManager.setPage(${this.currentPage - 1})">← Previous</button>`;
        }
        
        // Page numbers
        for (let i = 1; i <= totalPages; i++) {
            const isActive = i === this.currentPage ? 'active' : '';
            paginationHTML += `<button class="pagination-btn ${isActive}" onclick="blogManager.setPage(${i})">${i}</button>`;
        }
        
        // Next button
        if (this.currentPage < totalPages) {
            paginationHTML += `<button class="pagination-btn" onclick="blogManager.setPage(${this.currentPage + 1})">Next →</button>`;
        }
        
        pagination.innerHTML = paginationHTML;
    }

    setPage(page) {
        this.currentPage = page;
        this.renderPosts();
        
        // Scroll to top of blog section
        document.querySelector('.blog-content').scrollIntoView({ 
            behavior: 'smooth' 
        });
    }
}

// Initialize blog manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.blogManager = new BlogManager();
});

// Export for potential use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = BlogManager;
}
