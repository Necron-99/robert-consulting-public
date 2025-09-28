/**
 * Version Management System for Robert Bailey Consulting Website
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
            console.log(`%cRobert Bailey Consulting Website`, 'color: #1a365d; font-weight: bold; font-size: 16px;');
            console.log(`%cVersion: ${this.versionData.version}`, 'color: #38a169; font-weight: bold;');
            console.log(`%cBuild: ${this.versionData.build}`, 'color: #2c5282;');
            console.log(`%cRelease: ${this.versionData.release}`, 'color: #d69e2e;');
            console.log(`%cFeatures: ${this.versionData.features.join(', ')}`, 'color: #4a5568;');
        }
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
