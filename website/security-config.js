/**
 * Security Configuration
 * Implements additional client-side security measures
 */

class SecurityConfig {
  constructor() {
    this.init();
  }

  init() {
    this.setupSecurityHeaders();
    this.setupCSRFProtection();
    this.setupRateLimiting();
    this.setupInputValidation();
    this.setupSessionSecurity();
  }

  // Setup security headers (additional client-side validation)
  setupSecurityHeaders() {
    // Prevent clickjacking
    if (window.top !== window.self) {
      window.top.location = window.self.location;
    }

    // Disable right-click context menu on sensitive pages
    if (window.location.pathname.includes('dashboard') || window.location.pathname.includes('stats')) {
      document.addEventListener('contextmenu', (event) => event.preventDefault());
    }

    // Disable text selection on sensitive elements
    const sensitiveElements = document.querySelectorAll('.nav-link, .btn, .form-group');
    sensitiveElements.forEach(el => {
      el.style.userSelect = 'none';
      el.style.webkitUserSelect = 'none';
    });
  }

  // Setup CSRF protection
  setupCSRFProtection() {
    // Generate CSRF token
    const csrfToken = this.generateCSRFToken();
    sessionStorage.setItem('csrf_token', csrfToken);

    // Add CSRF token to all existing forms
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
      this.addCSRFTokenToForm(form, csrfToken);
    });

    // Watch for dynamically added forms
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === 1) { // Element node
            if (node.tagName === 'FORM') {
              this.addCSRFTokenToForm(node, csrfToken);
            }
            // Check for forms within added nodes
            const forms = node.querySelectorAll && node.querySelectorAll('form');
            if (forms) {
              forms.forEach(form => this.addCSRFTokenToForm(form, csrfToken));
            }
          }
        });
      });
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  // Add CSRF token to a specific form
  addCSRFTokenToForm(form, token) {
    // Check if token already exists
    if (form.querySelector('input[name="csrf_token"]')) {
      return;
    }

    const csrfInput = document.createElement('input');
    csrfInput.type = 'hidden';
    csrfInput.name = 'csrf_token';
    csrfInput.value = token;
    form.appendChild(csrfInput);
  }

  // Generate CSRF token
  generateCSRFToken() {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2);
    return btoa(`${timestamp}-${random}-${navigator.userAgent.substring(0, 20)}`);
  }

  // Validate CSRF token
  validateCSRFToken(token) {
    const storedToken = sessionStorage.getItem('csrf_token');
    if (!storedToken) {
      // If no stored token, generate a new one and allow the request
      const newToken = this.generateCSRFToken();
      sessionStorage.setItem('csrf_token', newToken);
      return true; // Allow first request
    }
    return token === storedToken;
  }

  // Setup rate limiting
  setupRateLimiting() {
    this.rateLimitStore = JSON.parse(localStorage.getItem('rate_limit') || '{}');

    // Clean old entries
    const now = Date.now();
    Object.keys(this.rateLimitStore).forEach(key => {
      let timestamp;
      switch (key) {
      case 'login_attempts':
        timestamp = this.rateLimitStore.login_attempts;
        break;
      case 'api_calls':
        timestamp = this.rateLimitStore.api_calls;
        break;
      case 'form_submissions':
        timestamp = this.rateLimitStore.form_submissions;
        break;
      default:
        timestamp = 0;
      }
      if (now - timestamp > 60000) { // 1 minute
        switch (key) {
        case 'login_attempts':
          delete this.rateLimitStore.login_attempts;
          break;
        case 'api_calls':
          delete this.rateLimitStore.api_calls;
          break;
        case 'form_submissions':
          delete this.rateLimitStore.form_submissions;
          break;
        }
      }
    });
  }

  // Check rate limit
  checkRateLimit(action, limit = 5) {
    const now = Date.now();
    const key = `${action}_${Math.floor(now / 60000)}`; // Per minute

    let currentCount;
    switch (key) {
    case 'login_attempts':
      currentCount = this.rateLimitStore.login_attempts || 0;
      break;
    case 'api_calls':
      currentCount = this.rateLimitStore.api_calls || 0;
      break;
    case 'form_submissions':
      currentCount = this.rateLimitStore.form_submissions || 0;
      break;
    default:
      currentCount = 0;
    }

    if (currentCount >= limit) {
      return false;
    }

    switch (key) {
    case 'login_attempts':
      this.rateLimitStore.login_attempts = (this.rateLimitStore.login_attempts || 0) + 1;
      break;
    case 'api_calls':
      this.rateLimitStore.api_calls = (this.rateLimitStore.api_calls || 0) + 1;
      break;
    case 'form_submissions':
      this.rateLimitStore.form_submissions = (this.rateLimitStore.form_submissions || 0) + 1;
      break;
    }
    localStorage.setItem('rate_limit', JSON.stringify(this.rateLimitStore));
    return true;
  }

  // Setup input validation
  setupInputValidation() {
    // Sanitize inputs only on blur (when user finishes typing)
    const inputs = document.querySelectorAll('input, textarea');
    inputs.forEach(input => {
      input.addEventListener('blur', (event) => {
        this.sanitizeInput(event.target);
      });
    });
  }

  // Sanitize input
  sanitizeInput(input) {
    const value = input.value;

    // Only sanitize if the input contains potentially dangerous content
    // Don't sanitize normal text input including spaces
    if (value.includes('<') || value.includes('>') ||
            value.toLowerCase().includes('javascript:') ||
            /on\w+=/gi.test(value)) {

      // Remove potentially dangerous characters
      const sanitized = value
        .replace(/[<>]/g, '') // Remove < and >
        .replace(/javascript:/gi, '') // Remove javascript: protocol
        .replace(/on\w+=/gi, '') // Remove event handlers
        .trim();

      if (sanitized !== value) {
        input.value = sanitized;
      }
    }
  }

  // Setup session security
  setupSessionSecurity() {
    // Monitor for suspicious activity
    let suspiciousActivity = 0;

    // Track rapid clicks
    let clickCount = 0;
    let lastClickTime = 0;

    document.addEventListener('click', () => {
      const now = Date.now();
      if (now - lastClickTime < 100) { // Less than 100ms between clicks
        clickCount++;
        if (clickCount > 10) {
          suspiciousActivity++;
        }
      } else {
        clickCount = 0;
      }
      lastClickTime = now;
    });

    // Track rapid keystrokes
    let keyCount = 0;
    let lastKeyTime = 0;

    document.addEventListener('keydown', () => {
      const now = Date.now();
      if (now - lastKeyTime < 50) { // Less than 50ms between keys
        keyCount++;
        if (keyCount > 20) {
          suspiciousActivity++;
        }
      } else {
        keyCount = 0;
      }
      lastKeyTime = now;
    });

    // Alert on suspicious activity
    if (suspiciousActivity > 5) {
      console.warn('Suspicious activity detected');
      // In production, send alert to server
    }
  }

  // Validate form submission
  validateFormSubmission(form) {
    // Check CSRF token (if present)
    const csrfToken = form.querySelector('input[name="csrf_token"]')?.value;
    if (csrfToken && !this.validateCSRFToken(csrfToken)) {
      throw new Error('Invalid CSRF token');
    }

    // Check rate limit
    if (!this.checkRateLimit('form_submission', 3)) {
      throw new Error('Too many form submissions. Please wait.');
    }

    // Validate inputs
    const inputs = form.querySelectorAll('input, textarea');
    inputs.forEach(input => {
      if (input.required && !input.value.trim()) {
        throw new Error(`${input.name} is required`);
      }

      // Email validation
      if (input.type === 'email' && input.value) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(input.value)) {
          throw new Error('Invalid email format');
        }
      }
    });

    return true;
  }

  // Secure logout
  secureLogout() {
    // Clear all sensitive data
    sessionStorage.clear();
    localStorage.removeItem('rate_limit');
    localStorage.removeItem('login_attempts');

    // Clear any cached data
    if ('caches' in window) {
      caches.keys().then(names => {
        names.forEach(name => {
          caches.delete(name);
        });
      });
    }
  }
}

// Initialize security configuration
document.addEventListener('DOMContentLoaded', () => {
  window.securityConfig = new SecurityConfig();
});
