// Easter Egg - Konami Code for Admin Access
// Non-obvious way to navigate between main site and admin site

class EasterEgg {
  constructor() {
    this.konamiCode = [
      'ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown',
      'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight',
      'KeyB', 'KeyA'
    ];
    this.userInput = [];
    this.isActive = false;
    this.timeout = null;

    this.init();
  }

  init() {
    // Listen for keydown events
    document.addEventListener('keydown', (e) => this.handleKeyPress(e));

    // Add subtle visual indicator that something is listening
    this.addVisualIndicator();
  }

  handleKeyPress(event) {
    // Clear timeout if user is actively typing
    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    // Add current key to sequence
    this.userInput.push(event.code);

    // Keep only the last 10 keys (length of Konami code)
    if (this.userInput.length > this.konamiCode.length) {
      this.userInput.shift();
    }

    // Check if sequence matches Konami code
    if (this.checkSequence()) {
      this.activateEasterEgg();
    }

    // Reset sequence after 3 seconds of inactivity
    this.timeout = setTimeout(() => {
      this.userInput = [];
    }, 3000);
  }

  checkSequence() {
    if (this.userInput.length !== this.konamiCode.length) {
      return false;
    }

    for (let i = 0; i < this.userInput.length; i++) {
      const userKey = this.userInput.at(i);
      const expectedKey = this.konamiCode.at(i);
      if (userKey !== expectedKey) {
        return false;
      }
    }
    return true;
  }

  activateEasterEgg() {
    if (this.isActive) {
      return;
    }

    this.isActive = true;
    this.userInput = [];

    // Show activation feedback
    this.showActivationFeedback();

    // Navigate to admin site after a brief delay
    setTimeout(() => {
      this.navigateToAdmin();
    }, 1500);
  }

  showActivationFeedback() {
    // Create a subtle notification
    const notification = document.createElement('div');
    notification.className = 'easter-egg-notification';
    notification.innerHTML = `
            <div class="easter-egg-content">
                <span class="easter-egg-icon">🎮</span>
                <span class="easter-egg-text">Access Granted</span>
            </div>
        `;

    // Add styles
    notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px 20px;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            z-index: 10000;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 14px;
            font-weight: 500;
            opacity: 0;
            transform: translateX(100%);
            transition: all 0.3s ease;
            cursor: pointer;
        `;

    // Add content styles
    const content = notification.querySelector('.easter-egg-content');
    content.style.cssText = `
            display: flex;
            align-items: center;
            gap: 10px;
        `;

    const icon = notification.querySelector('.easter-egg-icon');
    icon.style.cssText = `
            font-size: 18px;
        `;

    const text = notification.querySelector('.easter-egg-text');
    text.style.cssText = `
            font-weight: 600;
        `;

    // Add to page
    document.body.appendChild(notification);

    // Animate in
    setTimeout(() => {
      notification.style.opacity = '1';
      notification.style.transform = 'translateX(0)';
    }, 100);

    // Add click to dismiss
    notification.addEventListener('click', () => {
      this.dismissNotification(notification);
    });

    // Auto-dismiss after 3 seconds
    setTimeout(() => {
      this.dismissNotification(notification);
    }, 3000);
  }

  dismissNotification(notification) {
    notification.style.opacity = '0';
    notification.style.transform = 'translateX(100%)';

    setTimeout(() => {
      if (notification.parentNode) {
        notification.parentNode.removeChild(notification);
      }
    }, 300);
  }

  navigateToAdmin() {
    // Determine the admin URL based on current domain with validation
    const currentHost = window.location.hostname;
    let adminUrl;

    // Validate and sanitize the hostname
    const allowedHosts = [
      'robertconsulting.net',
      'www.robertconsulting.net',
      'admin.robertconsulting.net',
      'localhost',
      '127.0.0.1'
    ];

    if (!allowedHosts.includes(currentHost) && !currentHost.includes('localhost') && !currentHost.includes('127.0.0.1')) {
      console.error('Invalid hostname for admin navigation');
      return;
    }

    if (currentHost === 'robertconsulting.net' || currentHost === 'www.robertconsulting.net') {
      adminUrl = 'https://admin.robertconsulting.net';
    } else if (currentHost === 'admin.robertconsulting.net') {
      // If already on admin, go back to main site
      adminUrl = 'https://robertconsulting.net';
    } else {
      // Fallback for local development - use safe defaults
      adminUrl = currentHost.includes('admin')
        ? 'http://localhost:3000'
        : 'http://admin.localhost:3000';
    }

    // Validate the final URL before navigation
    try {
      const url = new URL(adminUrl);
      // Use the url variable to avoid no-new error
      if (!url) {
        return;
      }
    } catch {
      console.error('Invalid admin URL constructed');
      return;
    }

    // Show navigation message
    this.showNavigationMessage(adminUrl);

    // Navigate after a brief delay
    setTimeout(() => {
      window.location.href = adminUrl;
    }, 2000);
  }

  showNavigationMessage(url) {
    const message = document.createElement('div');
    message.className = 'easter-egg-navigation';
    message.innerHTML = `
            <div class="easter-egg-nav-content">
                <span class="easter-egg-nav-icon">🚀</span>
                <span class="easter-egg-nav-text">Navigating to ${url.includes('admin') ? 'Admin Panel' : 'Main Site'}...</span>
            </div>
        `;

    message.style.cssText = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0, 0, 0, 0.9);
            color: white;
            padding: 20px 30px;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.3);
            z-index: 10001;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            font-size: 16px;
            font-weight: 500;
            opacity: 0;
            transition: all 0.3s ease;
        `;

    const content = message.querySelector('.easter-egg-nav-content');
    content.style.cssText = `
            display: flex;
            align-items: center;
            gap: 15px;
        `;

    const icon = message.querySelector('.easter-egg-nav-icon');
    icon.style.cssText = `
            font-size: 24px;
            animation: pulse 1s infinite;
        `;

    // Add pulse animation
    const style = document.createElement('style');
    style.textContent = `
            @keyframes pulse {
                0%, 100% { transform: scale(1); }
                50% { transform: scale(1.1); }
            }
        `;
    document.head.appendChild(style);

    document.body.appendChild(message);

    // Animate in
    setTimeout(() => {
      message.style.opacity = '1';
    }, 100);
  }

  addVisualIndicator() {
    // Add a very subtle indicator that something is listening
    // This could be a small dot or icon that's barely visible
    const indicator = document.createElement('div');
    indicator.className = 'easter-egg-indicator';
    indicator.innerHTML = '●';

    indicator.style.cssText = `
            position: fixed;
            bottom: 20px;
            right: 20px;
            color: rgba(102, 126, 234, 0.3);
            font-size: 8px;
            z-index: 9999;
            pointer-events: none;
            transition: opacity 0.3s ease;
        `;

    document.body.appendChild(indicator);

    // Make it slightly more visible on hover
    indicator.addEventListener('mouseenter', () => {
      indicator.style.opacity = '0.6';
    });

    indicator.addEventListener('mouseleave', () => {
      indicator.style.opacity = '0.3';
    });
  }
}

// Initialize the easter egg when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  const easterEgg = new EasterEgg();
  // Store reference to avoid no-new error
  window.easterEggInstance = easterEgg;
});

// Export for potential external use
window.EasterEgg = EasterEgg;
