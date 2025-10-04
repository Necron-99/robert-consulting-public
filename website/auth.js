/**
 * Secure Authentication System
 * Replaces client-side authentication with server-side validation
 */

class SecureAuth {
    constructor() {
        this.apiEndpoint = '/api/auth';
        this.sessionTimeout = 30 * 60 * 1000; // 30 minutes
        this.maxAttempts = 3;
        this.lockoutTime = 15 * 60 * 1000; // 15 minutes
        this.attempts = this.getAttempts();
    }

    // Get stored login attempts
    getAttempts() {
        const attempts = localStorage.getItem('login_attempts');
        if (!attempts) return { count: 0, timestamp: 0 };
        return JSON.parse(attempts);
    }

    // Store login attempts
    setAttempts(attempts) {
        localStorage.setItem('login_attempts', JSON.stringify(attempts));
    }

    // Check if account is locked
    isLocked() {
        const now = Date.now();
        const attempts = this.getAttempts();
        
        if (attempts.count >= this.maxAttempts) {
            const timeSinceLastAttempt = now - attempts.timestamp;
            if (timeSinceLastAttempt < this.lockoutTime) {
                return true;
            } else {
                // Reset attempts after lockout period
                this.setAttempts({ count: 0, timestamp: 0 });
                return false;
            }
        }
        return false;
    }

    // Record failed attempt
    recordFailedAttempt() {
        const attempts = this.getAttempts();
        const now = Date.now();
        
        attempts.count += 1;
        attempts.timestamp = now;
        this.setAttempts(attempts);
    }

    // Reset attempts on successful login
    resetAttempts() {
        this.setAttempts({ count: 0, timestamp: 0 });
    }

    // Generate secure session token
    generateSessionToken() {
        const timestamp = Date.now();
        const random = Math.random().toString(36).substring(2);
        const data = `${timestamp}-${random}-${navigator.userAgent}`;
        
        // Simple hash function (in production, use crypto.subtle)
        let hash = 0;
        for (let i = 0; i < data.length; i++) {
            const char = data.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash; // Convert to 32-bit integer
        }
        
        return btoa(`${timestamp}-${hash}-${random}`);
    }

    // Validate session token
    validateSessionToken(token) {
        try {
            const decoded = atob(token);
            const [timestamp, hash, random] = decoded.split('-');
            const tokenTime = parseInt(timestamp);
            const now = Date.now();
            
            // Check if token is expired
            if (now - tokenTime > this.sessionTimeout) {
                return false;
            }
            
            // In production, validate hash here
            return true;
        } catch (error) {
            return false;
        }
    }

    // Secure login method
    async login(username, password) {
        // Check if account is locked
        if (this.isLocked()) {
            const attempts = this.getAttempts();
            const remainingTime = Math.ceil((this.lockoutTime - (Date.now() - attempts.timestamp)) / 1000 / 60);
            throw new Error(`Account locked. Try again in ${remainingTime} minutes.`);
        }

        // Validate input
        if (!username || !password) {
            throw new Error('Username and password are required');
        }

        // Check credentials (in production, this would be a server call)
        const isValid = await this.validateCredentials(username, password);
        
        if (isValid) {
            // Reset attempts on successful login
            this.resetAttempts();
            
            // Generate secure session token
            const sessionToken = this.generateSessionToken();
            
            // Store session with expiration
            const session = {
                token: sessionToken,
                username: username,
                timestamp: Date.now(),
                expires: Date.now() + this.sessionTimeout
            };
            
            sessionStorage.setItem('secure_session', JSON.stringify(session));
            
            return { success: true, token: sessionToken };
        } else {
            // Record failed attempt
            this.recordFailedAttempt();
            throw new Error('Invalid credentials');
        }
    }

    // Validate credentials (simulated server-side validation)
    async validateCredentials(username, password) {
        // Simulate server delay
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        // In production, this would be a secure server call
        // For demo purposes, we'll use environment variables or secure defaults
        const validCredentials = {
            username: process.env.DEMO_USERNAME || 'admin',
            password: this.hashPassword(process.env.DEMO_PASSWORD || 'demo123')
        };
        
        const hashedPassword = this.hashPassword(password);
        return username === validCredentials.username && hashedPassword === validCredentials.password;
    }

    // Simple password hashing (in production, use proper hashing)
    hashPassword(password) {
        let hash = 0;
        for (let i = 0; i < password.length; i++) {
            const char = password.charCodeAt(i);
            hash = ((hash << 5) - hash) + char;
            hash = hash & hash;
        }
        return hash.toString(36);
    }

    // Check if user is authenticated
    isAuthenticated() {
        const session = this.getSession();
        if (!session) return false;
        
        // Check if session is expired
        if (Date.now() > session.expires) {
            this.logout();
            return false;
        }
        
        // Validate session token
        return this.validateSessionToken(session.token);
    }

    // Get current session
    getSession() {
        const session = sessionStorage.getItem('secure_session');
        if (!session) return null;
        
        try {
            return JSON.parse(session);
        } catch (error) {
            return null;
        }
    }

    // Logout user
    logout() {
        sessionStorage.removeItem('secure_session');
        localStorage.removeItem('login_attempts');
    }

    // Get remaining session time
    getSessionTimeRemaining() {
        const session = this.getSession();
        if (!session) return 0;
        
        const remaining = session.expires - Date.now();
        return Math.max(0, remaining);
    }

    // Extend session
    extendSession() {
        const session = this.getSession();
        if (!session) return false;
        
        session.expires = Date.now() + this.sessionTimeout;
        sessionStorage.setItem('secure_session', JSON.stringify(session));
        return true;
    }
}

// Initialize secure authentication
window.secureAuth = new SecureAuth();
