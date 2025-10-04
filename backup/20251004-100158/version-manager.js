/**
 * Version Management System for Robert Consulting Website
 * Handles version updates, changelog management, and deployment tracking
 */

class VersionManager {
    constructor() {
        this.versionFile = 'version.json';
        this.currentVersion = null;
        this.versionData = null;
    }

    /**
     * Load version information from version.json
     */
    async loadVersion() {
        try {
            const response = await fetch(this.versionFile);
            this.versionData = await response.json();
            this.currentVersion = this.versionData.version;
            return this.versionData;
        } catch (error) {
            console.error('Failed to load version information:', error);
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
     * Initialize version management
     */
    async init() {
        await this.loadVersion();
        this.displayVersionInfo();
        return this.versionData;
    }
}

// Global version manager instance
window.versionManager = new VersionManager();

// Auto-initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.versionManager.init();
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = VersionManager;
}
