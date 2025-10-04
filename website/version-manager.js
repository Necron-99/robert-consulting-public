/**
 * Version Management System for Robert Consulting Website
 * Handles version updates, changelog management, and deployment tracking
 */

class VersionManager {
    constructor() {
        this.versionFile = './version.json';
        this.currentVersion = null;
        this.versionData = null;
    }

    /**
     * Load version information from version.json
     */
    async loadVersion() {
        try {
            console.log('Loading version from:', this.versionFile);
            const response = await fetch(this.versionFile);
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            this.versionData = await response.json();
            this.currentVersion = this.versionData.version;
            console.log('Version data loaded successfully:', this.versionData);
            return this.versionData;
        } catch (error) {
            console.error('Failed to load version information:', error);
            console.error('Trying fallback...');
            
            // Try fallback
            try {
                const fallbackResponse = await fetch('./version-fallback.json');
                if (fallbackResponse.ok) {
                    this.versionData = await fallbackResponse.json();
                    this.currentVersion = this.versionData.version;
                    console.log('Fallback version data loaded:', this.versionData);
                    return this.versionData;
                }
            } catch (fallbackError) {
                console.error('Fallback also failed:', fallbackError);
            }
            
            return null;
        }
    }

    /**
     * Get current version
     */
    getCurrentVersion() {
        return this.currentVersion;
    }

    /**
     * Get version data
     */
    getVersionData() {
        return this.versionData;
    }

    /**
     * Check if version is latest
     */
    isLatestVersion() {
        return this.versionData && this.versionData.release === 'stable';
    }

    /**
     * Get changelog for a specific version
     */
    getChangelog(version = null) {
        if (!this.versionData) return null;
        
        const targetVersion = version || this.currentVersion;
        return this.versionData.changelog.find(entry => entry.version === targetVersion);
    }

    /**
     * Get all changelog entries
     */
    getAllChangelog() {
        return this.versionData ? this.versionData.changelog : [];
    }

    /**
     * Display version information in console
     */
    displayVersionInfo() {
        if (this.versionData) {
            console.log(`%cRobert Consulting Website`, 'color: #1a365d; font-weight: bold; font-size: 16px;');
            console.log(`%cVersion: ${this.versionData.version}`, 'color: #38a169; font-weight: bold;');
            console.log(`%cBuild: ${this.versionData.build}`, 'color: #2c5282;');
            console.log(`%cRelease: ${this.versionData.release}`, 'color: #d69e2e;');
            console.log(`%cCommit: ${this.versionData.commit}`, 'color: #4a5568;');
            console.log(`%cBranch: ${this.versionData.branch}`, 'color: #4a5568;');
            console.log(`%cSecurity: ${this.versionData.security.status}`, 'color: #38a169;');
            console.log(`%cVulnerabilities: ${this.versionData.security.vulnerabilities}`, 'color: #e53e3e;');
            console.log(`%cFeatures: ${this.versionData.features.join(', ')}`, 'color: #4a5568;');
        }
    }

    /**
     * Get security information
     */
    getSecurityInfo() {
        return this.versionData ? this.versionData.security : null;
    }

    /**
     * Get build information
     */
    getBuildInfo() {
        return this.versionData ? {
            version: this.versionData.version,
            build: this.versionData.build,
            commit: this.versionData.commit,
            branch: this.versionData.branch,
            actor: this.versionData.actor,
            runNumber: this.versionData.run_number,
            workflow: this.versionData.workflow
        } : null;
    }

    /**
     * Check if security is up to date
     */
    isSecurityUpToDate() {
        if (!this.versionData || !this.versionData.security) return false;
        return this.versionData.security.status === 'secure' && 
               this.versionData.security.vulnerabilities === '0';
    }

    /**
     * Update DOM elements with version information
     */
    updateDOMElements() {
        if (!this.versionData) return;
        
        // Update version display
        const versionDisplay = document.getElementById('version-display');
        if (versionDisplay) {
            versionDisplay.textContent = `v${this.versionData.version}`;
        }
        
        // Update build display
        const buildDisplay = document.getElementById('build-display');
        if (buildDisplay) {
            let buildDate = this.versionData.build;
            if (buildDate.includes('T')) {
                // If it's an ISO timestamp, extract just the date part
                buildDate = buildDate.split('T')[0];
            }
            buildDisplay.textContent = `Build ${buildDate}`;
        }
        
        // Update security status
        const securityStatus = document.getElementById('security-status');
        if (securityStatus && this.versionData.security) {
            const security = this.versionData.security;
            let statusIcon = '🔒';
            let statusText = 'secure';
            let statusColor = '#10b981';
            
            if (security.status === 'secure') {
                statusIcon = '🔒';
                statusText = 'secure';
                statusColor = '#10b981';
            } else if (security.status === 'warning') {
                statusIcon = '⚠️';
                statusText = 'warning';
                statusColor = '#f59e0b';
            } else if (security.status === 'critical') {
                statusIcon = '🚨';
                statusText = 'critical';
                statusColor = '#ef4444';
            }
            
            securityStatus.innerHTML = `<span style="color: ${statusColor}; font-weight: bold;">${statusIcon} ${statusText}</span>`;
        }
    }


    /**
     * Initialize version management
     */
    async init() {
        await this.loadVersion();
        this.displayVersionInfo();
        this.updateDOMElements();
        return this.versionData;
    }
}

// Global version manager instance
window.versionManager = new VersionManager();

// Auto-initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM loaded, initializing version manager...');
    window.versionManager.init().then(() => {
        console.log('Version manager initialization completed');
    }).catch(error => {
        console.error('Version manager initialization failed:', error);
    });
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = VersionManager;
}
