/**
 * Simple Version Updater
 * Updates version information in the footer
 */

(function() {
  'use strict';

  console.log('🔄 Version updater starting...');

  async function updateVersionInfo() {
    try {
      console.log('📡 Fetching version.json...');
      const response = await fetch('./version.json');

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const data = await response.json();
      console.log('✅ Version data loaded:', data);

      // Update version display
      const versionDisplay = document.getElementById('version-display');
      if (versionDisplay) {
        versionDisplay.textContent = `v${data.version}`;
        console.log('✅ Updated version display');
      } else {
        console.warn('⚠️ Version display element not found');
      }

      // Update build display
      const buildDisplay = document.getElementById('build-display');
      if (buildDisplay) {
        let buildDate = data.build;
        if (buildDate.includes('T')) {
          buildDate = buildDate.split('T')[0];
        }
        buildDisplay.textContent = `Build ${buildDate}`;
        console.log('✅ Updated build display');
      } else {
        console.warn('⚠️ Build display element not found');
      }

      // Update security status
      const securityStatus = document.getElementById('security-status');
      if (securityStatus && data.security) {
        const security = data.security;
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
        console.log('✅ Updated security status');
      } else {
        console.warn('⚠️ Security status element not found or no security data');
      }

      console.log('🎉 Version update completed successfully');

    } catch (error) {
      console.error('❌ Version update failed:', error);

      // Try fallback
      try {
        console.log('🔄 Trying fallback...');
        const fallbackResponse = await fetch('./version-fallback.json');
        if (fallbackResponse.ok) {
          const fallbackData = await fallbackResponse.json();
          console.log('✅ Fallback data loaded:', fallbackData);

          // Update with fallback data
          const versionDisplay = document.getElementById('version-display');
          const buildDisplay = document.getElementById('build-display');

          if (versionDisplay) {
            versionDisplay.textContent = `v${fallbackData.version}`;
          }
          if (buildDisplay) {
            let buildDate = fallbackData.build;
            if (buildDate.includes('T')) {
              buildDate = buildDate.split('T')[0];
            }
            buildDisplay.textContent = `Build ${buildDate}`;
          }

          console.log('✅ Fallback update completed');
        }
      } catch (fallbackError) {
        console.error('❌ Fallback also failed:', fallbackError);
      }
    }
  }

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', updateVersionInfo);
  } else {
    updateVersionInfo();
  }

  // Also try after a short delay to ensure all elements are loaded
  setTimeout(updateVersionInfo, 1000);

}());
