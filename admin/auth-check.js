// Simple authentication check for admin pages
(function() {
    // Check if user is authenticated
    const isAuthenticated = sessionStorage.getItem('admin-authenticated') === 'true';
    const timestamp = sessionStorage.getItem('admin-timestamp');
    const now = Date.now();
    const sessionTimeout = 24 * 60 * 60 * 1000; // 24 hours
    
    if (!isAuthenticated || !timestamp || (now - timestamp > sessionTimeout)) {
        // Clear invalid session
        sessionStorage.removeItem('admin-authenticated');
        sessionStorage.removeItem('admin-timestamp');
        
        // Redirect to login
        window.location.href = '/login.html';
        return;
    }
    
    // Add logout functionality
    function addLogoutButton() {
        const logoutBtn = document.createElement('button');
        logoutBtn.innerHTML = '🚪 Logout';
        logoutBtn.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #e74c3c;
            color: white;
            border: none;
            padding: 10px 15px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            z-index: 1000;
        `;
        
        logoutBtn.addEventListener('click', function() {
            sessionStorage.removeItem('admin-authenticated');
            sessionStorage.removeItem('admin-timestamp');
            window.location.href = '/login.html';
        });
        
        document.body.appendChild(logoutBtn);
    }
    
    // Add logout button when page loads
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', addLogoutButton);
    } else {
        addLogoutButton();
    }
})();
