(function() {
  'use strict';

  function updateVersionDisplay() {
    try {
      let data;
      if (window.versionManager && typeof window.versionManager.generateVersionInfo === 'function') {
        data = window.versionManager.generateVersionInfo();
      } else {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const hour = String(now.getHours()).padStart(2, '0');
        const minute = String(now.getMinutes()).padStart(2, '0');
        data = {
          version: `1.${year.toString().slice(-2)}${month}${day}.${hour}${minute}`,
          buildFormatted: now.toISOString().split('T')[0]
        };
      }

      const versionDisplay = document.getElementById('version-display');
      if (versionDisplay && data.version) {
        versionDisplay.textContent = `v${data.version}`;
      }

      const buildDisplay = document.getElementById('build-display');
      if (buildDisplay && (data.buildFormatted || data.build)) {
        const buildText = data.buildFormatted || data.build;
        buildDisplay.textContent = `Build ${buildText}`;
      }

      const securityStatus = document.getElementById('security-status');
      if (securityStatus) {
        securityStatus.textContent = '🔒 secure';
      }
    } catch (err) {
      // Fail silently
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', updateVersionDisplay);
  } else {
    updateVersionDisplay();
  }

  setTimeout(updateVersionDisplay, 500);
}());


