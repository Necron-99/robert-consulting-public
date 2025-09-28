/**
 * Admin Dashboard Script
 * Handles authentication, statistics display, and real-time updates
 */

class Dashboard {
    constructor() {
        this.isAuthenticated = false;
        this.statsData = {
            visitors: 1247,
            pageViews: 3421,
            avgSession: 145,
            contactForms: 23,
            loadTime: 1.2,
            seoScore: 95,
            uptime: 99.9
        };
        this.init();
    }

    init() {
        this.checkAuthentication();
        this.setupEventListeners();
        this.loadStats();
        this.startRealTimeUpdates();
    }

    checkAuthentication() {
        if (window.secureAuth && window.secureAuth.isAuthenticated()) {
            this.isAuthenticated = true;
            this.showDashboard();
            this.startSessionTimer();
        } else {
            this.showLoginModal();
        }
    }

    setupEventListeners() {
        // Login form
        const loginForm = document.getElementById('login-form');
        if (loginForm) {
            loginForm.addEventListener('submit', (e) => this.handleLogin(e));
        }

        // Logout button
        const logoutBtn = document.getElementById('logout-btn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', () => this.handleLogout());
        }
    }

    async handleLogin(e) {
        e.preventDefault();
        const formData = new FormData(e.target);
        const username = formData.get('username');
        const password = formData.get('password');

        try {
            // Use secure authentication
            if (window.secureAuth) {
                const result = await window.secureAuth.login(username, password);
                if (result.success) {
                    this.isAuthenticated = true;
                    this.hideLoginModal();
                    this.showDashboard();
                    this.startSessionTimer();
                }
            } else {
                throw new Error('Authentication system not available');
            }
        } catch (error) {
            alert(`Login failed: ${error.message}`);
        }
    }

    handleLogout() {
        if (window.secureAuth) {
            window.secureAuth.logout();
        }
        this.isAuthenticated = false;
        this.showLoginModal();
    }

    showLoginModal() {
        const modal = document.getElementById('login-modal');
        if (modal) {
            modal.style.display = 'block';
        }
        // Hide dashboard content
        const adminContainer = document.querySelector('.admin-container');
        if (adminContainer) {
            adminContainer.style.display = 'none';
        }
    }

    hideLoginModal() {
        const modal = document.getElementById('login-modal');
        if (modal) {
            modal.style.display = 'none';
        }
    }

    showDashboard() {
        const modal = document.getElementById('login-modal');
        const adminContainer = document.querySelector('.admin-container');
        
        if (modal) {
            modal.style.display = 'none';
        }
        if (adminContainer) {
            adminContainer.style.display = 'block';
        }
    }

    loadStats() {
        if (!this.isAuthenticated) return;

        // Update visitor count with animation
        this.animateNumber('total-visitors', this.statsData.visitors);
        this.animateNumber('page-views', this.statsData.pageViews);
        this.animateNumber('avg-session', this.statsData.avgSession, 's');
        this.animateNumber('contact-forms', this.statsData.contactForms);
        this.animateNumber('load-time', this.statsData.loadTime, 's');
        this.animateNumber('seo-score', this.statsData.seoScore);
        this.animateNumber('uptime', this.statsData.uptime, '%');

        // Update version information
        this.loadVersionInfo();
    }

    animateNumber(elementId, targetValue, suffix = '') {
        const element = document.getElementById(elementId);
        if (!element) return;

        const duration = 2000;
        const startValue = 0;
        const increment = targetValue / (duration / 16);
        let currentValue = startValue;

        const timer = setInterval(() => {
            currentValue += increment;
            if (currentValue >= targetValue) {
                currentValue = targetValue;
                clearInterval(timer);
            }
            
            if (suffix === 's' && targetValue < 10) {
                element.textContent = currentValue.toFixed(1) + suffix;
            } else if (suffix === '%') {
                element.textContent = currentValue.toFixed(1) + suffix;
            } else {
                element.textContent = Math.floor(currentValue).toLocaleString() + suffix;
            }
        }, 16);
    }

    async loadVersionInfo() {
        try {
            const response = await fetch('version.json');
            const versionData = await response.json();
            
            const currentVersion = document.getElementById('current-version');
            const versionDate = document.getElementById('version-date');
            const deploymentTime = document.getElementById('deployment-time');
            
            if (currentVersion) {
                currentVersion.textContent = `v${versionData.version}`;
            }
            
            if (versionDate) {
                versionDate.textContent = `Build: ${versionData.build}`;
            }
            
            if (deploymentTime) {
                const now = new Date();
                deploymentTime.textContent = `Last deployed: ${now.toISOString().split('T')[0]} ${now.toTimeString().split(' ')[0]} UTC`;
            }
        } catch (error) {
            console.warn('Could not load version information:', error);
        }
    }

    startRealTimeUpdates() {
        if (!this.isAuthenticated) return;

        // Simulate real-time updates every 30 seconds
        setInterval(() => {
            this.updateRealTimeStats();
        }, 30000);

        // Initial update
        this.updateRealTimeStats();
    }

    startSessionTimer() {
        if (!this.isAuthenticated) return;

        // Check session every minute
        this.sessionTimer = setInterval(() => {
            if (window.secureAuth && !window.secureAuth.isAuthenticated()) {
                this.handleLogout();
                alert('Session expired. Please log in again.');
            }
        }, 60000);

        // Show session timeout warning
        const warningTime = 5 * 60 * 1000; // 5 minutes before expiry
        setTimeout(() => {
            if (this.isAuthenticated) {
                const extend = confirm('Your session will expire in 5 minutes. Extend session?');
                if (extend && window.secureAuth) {
                    window.secureAuth.extendSession();
                }
            }
        }, window.secureAuth ? window.secureAuth.getSessionTimeRemaining() - warningTime : 0);
    }

    updateRealTimeStats() {
        // Simulate small random changes to make it feel real-time
        const randomChange = () => Math.floor(Math.random() * 3) - 1; // -1, 0, or 1
        
        // Update visitor count
        this.statsData.visitors += randomChange();
        document.getElementById('total-visitors').textContent = this.statsData.visitors.toLocaleString();
        
        // Update page views
        this.statsData.pageViews += randomChange() * 2;
        document.getElementById('page-views').textContent = this.statsData.pageViews.toLocaleString();
        
        // Update session duration
        this.statsData.avgSession += randomChange();
        document.getElementById('avg-session').textContent = this.statsData.avgSession + 's';
    }

    // Method to add new activity (can be called from contact form)
    addActivity(type, description) {
        const activityFeed = document.querySelector('.activity-feed');
        if (!activityFeed) return;

        const activityItem = document.createElement('div');
        activityItem.className = 'activity-item';
        
        const icons = {
            'contact': '📧',
            'visitor': '👥',
            'search': '🔍',
            'mobile': '📱'
        };
        
        const now = new Date();
        const timeString = this.getTimeAgo(now);
        
        activityItem.innerHTML = `
            <div class="activity-icon">${icons[type] || '📄'}</div>
            <div class="activity-content">
                <h4>${this.getActivityTitle(type)}</h4>
                <p>${description}</p>
                <span class="activity-time">${timeString}</span>
            </div>
        `;
        
        // Insert at the top
        activityFeed.insertBefore(activityItem, activityFeed.firstChild);
        
        // Remove old activities (keep only last 10)
        const activities = activityFeed.querySelectorAll('.activity-item');
        if (activities.length > 10) {
            activities[activities.length - 1].remove();
        }
    }

    getActivityTitle(type) {
        const titles = {
            'contact': 'Contact Form Submission',
            'visitor': 'New Visitor',
            'search': 'Search Query',
            'mobile': 'Mobile Visit'
        };
        return titles[type] || 'New Activity';
    }

    getTimeAgo(date) {
        const now = new Date();
        const diffMs = now - date;
        const diffMins = Math.floor(diffMs / 60000);
        const diffHours = Math.floor(diffMins / 60);
        const diffDays = Math.floor(diffHours / 24);
        
        if (diffMins < 1) return 'Just now';
        if (diffMins < 60) return `${diffMins} minute${diffMins > 1 ? 's' : ''} ago`;
        if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
        return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.dashboard = new Dashboard();
});

// Export for external use
if (typeof module !== 'undefined' && module.exports) {
    module.exports = Dashboard;
}
