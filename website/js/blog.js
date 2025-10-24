// Blog Management System - Weekly Pagination
class BlogManager {
    constructor() {
        this.posts = [];
        this.weeklyPosts = {};
        this.currentFilter = 'all';
        this.currentWeek = null;
        this.availableWeeks = [];
        this.init();
    }

    init() {
        this.loadPosts();
        this.groupPostsByWeek();
        this.setupEventListeners();
        this.renderPosts();
    }

    loadPosts() {
        // Blog posts data - Multiple weeks of posts for weekly pagination
        this.posts = [
            // Week of October 20-24, 2025 (Current Week)
            {
                id: 1,
                title: "Terraform State Management: Best Practices for Team Collaboration",
                excerpt: "Learn how to implement secure, scalable Terraform state management for team environments with remote backends, locking, and state migration strategies.",
                content: "blog-posts/terraform-state-management-team-collaboration.html",
                date: "2025-10-23", // Thursday
                category: "terraform",
                tags: ["Terraform", "State Management", "Team Collaboration", "Remote Backend", "Locking", "IaC"],
                icon: "🏗️",
                readTime: "8 min read"
            },
            {
                id: 2,
                title: "DevSecOps Security Scanning: Building a Comprehensive Pipeline",
                excerpt: "Learn how to implement comprehensive security scanning in your DevSecOps pipeline with SAST, DAST, dependency scanning, and infrastructure security checks using modern tools.",
                content: "blog-posts/devsecops-security-scanning-pipeline.html",
                date: "2025-10-22", // Wednesday
                category: "security",
                tags: ["DevSecOps", "Security Scanning", "SAST", "DAST", "Pipeline", "Compliance"],
                icon: "🔒",
                readTime: "10 min read"
            },
            {
                id: 3,
                title: "GitOps with GitHub Actions: Automating Terraform Deployments",
                excerpt: "Learn how to implement GitOps workflows using GitHub Actions to automate Terraform deployments with proper approval gates, security scanning, and rollback capabilities.",
                content: "blog-posts/gitops-github-actions-terraform.html",
                date: "2025-10-21", // Tuesday
                category: "cicd",
                tags: ["GitOps", "GitHub Actions", "Terraform", "Automation", "Deployment", "CI/CD"],
                icon: "🚀",
                readTime: "9 min read"
            },
            {
                id: 4,
                title: "AWS Cost Optimization: 5 Strategies That Saved My Client $50K Annually",
                excerpt: "Learn how to implement intelligent caching, S3 lifecycle policies, and Lambda optimization to dramatically reduce AWS costs while maintaining performance.",
                content: "blog-posts/aws-cost-optimization.html",
                date: "2025-10-20", // Monday
                category: "aws",
                tags: ["AWS", "Cost Optimization", "S3 Lifecycle", "Lambda", "Cloud Savings", "Performance"],
                icon: "💰",
                readTime: "12 min read"
            },
            {
                id: 5,
                title: "Advanced Kubernetes Security Patterns",
                excerpt: "Learn enterprise-grade security patterns for Kubernetes clusters. Master RBAC, network policies, pod security standards, and advanced security controls for production environments.",
                content: "blog-posts/kubernetes-security-patterns.html",
                date: "2025-10-24", // Friday
                category: "kubernetes",
                tags: ["Kubernetes", "Security", "Enterprise", "RBAC", "Network Policies", "Pod Security"],
                icon: "🔒",
                readTime: "12 min read"
            },
            // Week of October 13-17, 2025 (Previous Week)
            {
                id: 6,
                title: "Terraform Module Design Patterns: Building Reusable Infrastructure Components",
                excerpt: "Master Terraform module design with proven patterns for reusability, maintainability, and scalability. Learn best practices for variable design, output patterns, and module composition.",
                content: "blog-posts/terraform-module-design-patterns.html",
                date: "2025-10-17", // Thursday
                category: "terraform",
                tags: ["Terraform", "Modules", "Design Patterns", "Reusability", "Infrastructure", "Best Practices"],
                icon: "🏗️",
                readTime: "9 min read"
            },
            {
                id: 7,
                title: "DevSecOps Security Scanning: Building a Comprehensive Pipeline",
                excerpt: "Learn how to implement comprehensive security scanning in your DevSecOps pipeline with SAST, DAST, dependency scanning, and infrastructure security checks using modern tools.",
                content: "blog-posts/devsecops-security-scanning-pipeline.html",
                date: "2025-10-16", // Wednesday
                category: "security",
                tags: ["DevSecOps", "Security Scanning", "SAST", "DAST", "Pipeline", "Compliance"],
                icon: "🔒",
                readTime: "10 min read"
            },
            {
                id: 8,
                title: "Database DevOps: Automating SQL Server Deployments with CI/CD",
                excerpt: "Learn how to integrate database changes into your CI/CD pipeline with automated schema migrations, data validation, and rollback procedures for SQL Server environments.",
                content: "blog-posts/database-devops-sql-server-automation.html",
                date: "2025-10-15", // Tuesday
                category: "devops",
                tags: ["Database DevOps", "SQL Server", "CI/CD", "Schema Migration", "Automation", "Data Validation"],
                icon: "🗄️",
                readTime: "7 min read"
            },
            {
                id: 9,
                title: "AWS Lambda Cold Start Optimization: From 3 Seconds to 200ms",
                excerpt: "Learn proven strategies to eliminate AWS Lambda cold starts and achieve sub-200ms response times. Includes connection pooling, provisioned concurrency, and memory optimization techniques.",
                content: "blog-posts/aws-lambda-cold-start-optimization.html",
                date: "2025-10-14", // Monday
                category: "aws",
                tags: ["AWS Lambda", "Performance", "Optimization", "Cold Start", "Connection Pooling", "Serverless"],
                icon: "⚡",
                readTime: "7 min read"
            },
            {
                id: 10,
                title: "AWS Well-Architected Framework: A Practical Implementation Guide",
                excerpt: "Apply the AWS Well-Architected Framework principles to design cost-effective, secure, and scalable cloud architectures. Learn practical implementation strategies for all five pillars.",
                content: "blog-posts/aws-well-architected-framework-implementation.html",
                date: "2025-10-11", // Friday
                category: "aws",
                tags: ["AWS", "Well-Architected", "Architecture", "Best Practices", "Security", "Cost Optimization"],
                icon: "🏛️",
                readTime: "13 min read"
            }
        ];
    }

    groupPostsByWeek() {
        this.weeklyPosts = {};
        this.availableWeeks = [];
        
        this.posts.forEach(post => {
            const date = new Date(post.date);
            const weekStart = this.getWeekStart(date);
            const weekKey = this.formatWeekKey(weekStart);
            
            if (!this.weeklyPosts[weekKey]) {
                this.weeklyPosts[weekKey] = {
                    weekStart: weekStart,
                    weekEnd: new Date(weekStart.getTime() + 6 * 24 * 60 * 60 * 1000),
                    posts: []
                };
                this.availableWeeks.push(weekKey);
            }
            
            this.weeklyPosts[weekKey].posts.push(post);
        });
        
        // Sort weeks in reverse chronological order (newest first)
        this.availableWeeks.sort((a, b) => new Date(b) - new Date(a));
        
        // Set current week to the most recent
        this.currentWeek = this.availableWeeks[0];
        
        // Debug: Log week information
        console.log('Available weeks:', this.availableWeeks);
        console.log('Current week:', this.currentWeek);
        console.log('Weekly posts:', this.weeklyPosts);
    }
    
    getWeekStart(date) {
        const newDate = new Date(date); // Create a copy to avoid mutating original
        const day = newDate.getDay();
        const diff = newDate.getDate() - day; // Sunday = 0, so no adjustment needed
        newDate.setDate(diff);
        newDate.setHours(0, 0, 0, 0); // Normalize to start of day
        return newDate;
    }
    
    formatWeekKey(date) {
        return date.toISOString().split('T')[0];
    }
    
    formatWeekDisplay(weekStart, weekEnd) {
        const startMonth = weekStart.toLocaleDateString('en-US', { month: 'short' });
        const startDay = weekStart.getDate();
        const endMonth = weekEnd.toLocaleDateString('en-US', { month: 'short' });
        const endDay = weekEnd.getDate();
        const year = weekStart.getFullYear();
        
        if (startMonth === endMonth) {
            return `${startMonth} ${startDay}-${endDay}, ${year}`;
        } else {
            return `${startMonth} ${startDay} - ${endMonth} ${endDay}, ${year}`;
        }
    }

    setupEventListeners() {
        // Filter buttons
        document.querySelectorAll('.filter-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
                e.target.classList.add('active');
                this.currentFilter = e.target.dataset.filter;
                this.renderPosts();
            });
        });
        
        // Week navigation buttons
        const prevWeekBtn = document.getElementById('prev-week-btn');
        const nextWeekBtn = document.getElementById('next-week-btn');
        
        if (prevWeekBtn) {
            prevWeekBtn.addEventListener('click', () => this.navigateWeek('prev'));
        }
        
        if (nextWeekBtn) {
            nextWeekBtn.addEventListener('click', () => this.navigateWeek('next'));
        }
    }
    
    navigateWeek(direction) {
        const currentIndex = this.availableWeeks.indexOf(this.currentWeek);
        let newIndex;
        
        if (direction === 'prev') {
            newIndex = currentIndex + 1;
        } else {
            newIndex = currentIndex - 1;
        }
        
        if (newIndex >= 0 && newIndex < this.availableWeeks.length) {
            this.currentWeek = this.availableWeeks[newIndex];
            this.renderPosts();
        }
    }

    renderPosts() {
        const blogGrid = document.getElementById('blog-grid');
        if (!blogGrid) return;

        // Get posts for current week
        const currentWeekData = this.weeklyPosts[this.currentWeek];
        if (!currentWeekData) return;

        // Filter posts by category if needed
        let postsToShow = currentWeekData.posts;
        if (this.currentFilter !== 'all') {
            postsToShow = currentWeekData.posts.filter(post => post.category === this.currentFilter);
        }

        // Sort posts in reverse chronological order (newest first)
        postsToShow.sort((a, b) => new Date(b.date) - new Date(a.date));

        // Clear existing posts
        blogGrid.innerHTML = '';

        // Render posts
        postsToShow.forEach(post => {
            const postElement = this.createPostElement(post);
            blogGrid.appendChild(postElement);
        });

        // Update week display and navigation
        this.updateWeekDisplay(currentWeekData);
        this.updateWeekNavigation();
        this.updatePostCount(postsToShow.length);
    }
    
        updateWeekDisplay(weekData) {
            const weekDisplay = document.getElementById('current-week');
            if (weekDisplay) {
                // Show actual post date range instead of calendar week
                const posts = weekData.posts;
                if (posts.length > 0) {
                    const dates = posts.map(post => new Date(post.date)).sort((a, b) => a - b);
                    const startDate = dates[0];
                    const endDate = dates[dates.length - 1];
                    weekDisplay.textContent = this.formatWeekDisplay(startDate, endDate);
                } else {
                    weekDisplay.textContent = this.formatWeekDisplay(weekData.weekStart, weekData.weekEnd);
                }
            }
        }
    
    updateWeekNavigation() {
        const currentIndex = this.availableWeeks.indexOf(this.currentWeek);
        const prevBtn = document.getElementById('prev-week-btn');
        const nextBtn = document.getElementById('next-week-btn');
        
        if (prevBtn) {
            prevBtn.disabled = currentIndex >= this.availableWeeks.length - 1;
            prevBtn.style.opacity = prevBtn.disabled ? '0.5' : '1';
        }
        
        if (nextBtn) {
            nextBtn.disabled = currentIndex <= 0;
            nextBtn.style.opacity = nextBtn.disabled ? '0.5' : '1';
        }
    }

    createPostElement(post) {
        const postDiv = document.createElement('div');
        postDiv.className = 'blog-card';
        postDiv.innerHTML = `
            <div class="blog-card-image">
                <span class="blog-icon">${post.icon}</span>
            </div>
            <div class="blog-card-content">
                <div class="blog-card-meta">
                    <span class="blog-card-date">${this.formatDate(post.date)}</span>
                    <span class="blog-card-category">${post.category.toUpperCase()}</span>
                    <span class="read-time">${post.readTime}</span>
                </div>
                <h3>${post.title}</h3>
                <p>${post.excerpt}</p>
                <div class="blog-card-tags">
                    ${post.tags.map(tag => `<span class="tag">${tag}</span>`).join('')}
                </div>
                <a href="${post.content}" class="blog-card-link">Read More →</a>
            </div>
        `;
        return postDiv;
    }

    formatDate(dateString) {
        // Parse date as local time to avoid timezone issues
        const [year, month, day] = dateString.split('-').map(Number);
        const date = new Date(year, month - 1, day);
        return date.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric' 
        });
    }

    updatePostCount(count) {
        const countElement = document.getElementById('post-count');
        if (countElement) {
            countElement.textContent = `Showing ${count} of ${this.posts.length} posts`;
        }
    }
}

// Initialize blog manager when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new BlogManager();
});
