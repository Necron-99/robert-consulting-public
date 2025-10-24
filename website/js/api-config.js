/**
 * API Configuration
 * Secure API endpoint configuration with authentication
 */

class APIConfig {
  constructor() {
    // API endpoint configuration
    this.baseURL = this.getAPIEndpoint();
    this.apiKey = this.getAPIKey();
    this.rateLimit = {
      maxRequests: 5,
      timeWindow: 60000, // 1 minute
      requests: []
    };
  }

  /**
     * Get API endpoint from environment or fallback
     */
  getAPIEndpoint() {
    // In production, this would come from environment variables
    // For now, we'll use a placeholder that should be replaced during deployment
    return process.env.CONTACT_API_URL || 'https://PLACEHOLDER_API_ENDPOINT/contact';
  }

  /**
     * Get API key from secure storage
     */
  getAPIKey() {
    // In production, this would come from environment variables or secure storage
    // For now, we'll use a placeholder that should be replaced during deployment
    return process.env.CONTACT_API_KEY || 'PLACEHOLDER_API_KEY';
  }

  /**
     * Check if we're within rate limits
     */
  isWithinRateLimit() {
    const now = Date.now();
    const oneMinuteAgo = now - this.rateLimit.timeWindow;

    // Remove old requests
    this.rateLimit.requests = this.rateLimit.requests.filter(time => time > oneMinuteAgo);

    // Check if we're within limits
    return this.rateLimit.requests.length < this.rateLimit.maxRequests;
  }

  /**
     * Record a request for rate limiting
     */
  recordRequest() {
    this.rateLimit.requests.push(Date.now());
  }

  /**
     * Make authenticated API request
     */
  async makeRequest(endpoint, data) {
    // Check rate limits
    if (!this.isWithinRateLimit()) {
      throw new Error('Rate limit exceeded. Please wait before submitting another request.');
    }

    // Record this request
    this.recordRequest();

    // Prepare headers
    const headers = {
      'Content-Type': 'application/json',
      'X-API-Key': this.apiKey,
      'X-Requested-With': 'XMLHttpRequest'
    };

    // Make the request
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(data)
    });

    // Check response status
    if (!response.ok) {
      if (response.status === 429) {
        throw new Error('Rate limit exceeded. Please try again later.');
      } else if (response.status === 401) {
        throw new Error('Authentication failed. Please refresh the page.');
      } else if (response.status === 403) {
        throw new Error('Access forbidden. Please check your permissions.');
      } else {
        throw new Error(`API request failed with status ${response.status}`);
      }
    }

    return await response.json();
  }

  /**
     * Submit contact form with security checks
     */
  async submitContactForm(formData) {
    // Validate form data
    if (!this.validateFormData(formData)) {
      throw new Error('Invalid form data provided');
    }

    // Add security headers and metadata
    const secureData = {
      ...formData,
      timestamp: new Date().toISOString(),
      userAgent: navigator.userAgent,
      referrer: document.referrer,
      security: {
        csrfToken: this.getCSRFToken(),
        sessionId: this.getSessionId()
      }
    };

    return await this.makeRequest('/contact', secureData);
  }

  /**
     * Validate form data
     */
  validateFormData(data) {
    const required = ['name', 'email', 'subject', 'message'];

    for (const field of required) {
      let fieldValue;
      switch (field) {
        case 'name':
          fieldValue = data.name;
          break;
        case 'email':
          fieldValue = data.email;
          break;
        case 'subject':
          fieldValue = data.subject;
          break;
        case 'message':
          fieldValue = data.message;
          break;
        default:
          fieldValue = null;
      }
      if (!fieldValue || fieldValue.trim().length === 0) {
        return false;
      }
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(data.email)) {
      return false;
    }

    // Length validation
    if (data.message.length > 5000) {
      return false;
    }

    return true;
  }

  /**
     * Get CSRF token
     */
  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
  }

  /**
     * Get session ID
     */
  getSessionId() {
    return sessionStorage.getItem('session_id') || this.generateSessionId();
  }

  /**
     * Generate session ID
     */
  generateSessionId() {
    const sessionId = 'sess_' + Math.random().toString(36).substr(2, 9);
    sessionStorage.setItem('session_id', sessionId);
    return sessionId;
  }
}

// Export for use in other scripts
window.APIConfig = APIConfig;
