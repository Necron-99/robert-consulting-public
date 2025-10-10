#!/bin/bash
# Simple authentication setup using a basic HTML login page

set -e

echo "🔐 Setting up simple authentication for admin site..."

# Create a simple login page
echo "📝 Creating login page..."
cat > admin/login.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login - Robert Consulting</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .login-container {
            background: white;
            padding: 2rem;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            width: 100%;
            max-width: 400px;
        }
        .logo {
            text-align: center;
            margin-bottom: 2rem;
        }
        .logo h1 {
            color: #333;
            margin: 0;
            font-size: 1.5rem;
        }
        .form-group {
            margin-bottom: 1rem;
        }
        label {
            display: block;
            margin-bottom: 0.5rem;
            color: #555;
            font-weight: 500;
        }
        input[type="text"], input[type="password"] {
            width: 100%;
            padding: 0.75rem;
            border: 2px solid #e1e5e9;
            border-radius: 5px;
            font-size: 1rem;
            transition: border-color 0.3s;
            box-sizing: border-box;
        }
        input[type="text"]:focus, input[type="password"]:focus {
            outline: none;
            border-color: #667eea;
        }
        .login-btn {
            width: 100%;
            padding: 0.75rem;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 1rem;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s;
        }
        .login-btn:hover {
            transform: translateY(-2px);
        }
        .error {
            color: #e74c3c;
            text-align: center;
            margin-top: 1rem;
            display: none;
        }
        .footer {
            text-align: center;
            margin-top: 2rem;
            color: #666;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="logo">
            <h1>🔐 Admin Access</h1>
            <p>Robert Consulting Admin Portal</p>
        </div>
        
        <form id="loginForm">
            <div class="form-group">
                <label for="username">Username:</label>
                <input type="text" id="username" name="username" required>
            </div>
            
            <div class="form-group">
                <label for="password">Password:</label>
                <input type="password" id="password" name="password" required>
            </div>
            
            <button type="submit" class="login-btn">Login</button>
            
            <div class="error" id="error">Invalid credentials. Please try again.</div>
        </form>
        
        <div class="footer">
            <p>Secure access to admin functions</p>
        </div>
    </div>

    <script>
        document.getElementById('loginForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            
            // Simple client-side authentication (for demo purposes)
            // In production, this should be server-side validation
            if (username === 'admin' && password === 'CHEQZvqKHsh9EyKv4ict') {
                // Store session token
                sessionStorage.setItem('admin-authenticated', 'true');
                sessionStorage.setItem('admin-timestamp', Date.now());
                
                // Redirect to admin dashboard
                window.location.href = '/index.html';
            } else {
                document.getElementById('error').style.display = 'block';
                setTimeout(() => {
                    document.getElementById('error').style.display = 'none';
                }, 3000);
            }
        });
        
        // Check if already authenticated
        if (sessionStorage.getItem('admin-authenticated') === 'true') {
            const timestamp = sessionStorage.getItem('admin-timestamp');
            const now = Date.now();
            const sessionTimeout = 24 * 60 * 60 * 1000; // 24 hours
            
            if (now - timestamp < sessionTimeout) {
                window.location.href = '/index.html';
            } else {
                sessionStorage.removeItem('admin-authenticated');
                sessionStorage.removeItem('admin-timestamp');
            }
        }
    </script>
</body>
</html>
EOF

# Create a simple auth check script for other pages
echo "📝 Creating authentication check script..."
cat > admin/auth-check.js << 'EOF'
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
EOF

# Update the main admin page to include auth check
echo "📝 Updating admin pages with authentication..."
if [ -f "admin/index.html" ]; then
    # Add auth check script to index.html
    sed -i.bak 's|</head>|    <script src="auth-check.js"></script>\n</head>|' admin/index.html
    echo "✅ Updated admin/index.html with authentication"
fi

if [ -f "admin/client-deployment.html" ]; then
    # Add auth check script to client-deployment.html
    sed -i.bak 's|</head>|    <script src="auth-check.js"></script>\n</head>|' admin/client-deployment.html
    echo "✅ Updated admin/client-deployment.html with authentication"
fi

# Create a simple redirect from root to login
echo "📝 Creating root redirect..."
cat > admin/redirect.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Redirecting...</title>
    <script>
        // Check if already authenticated
        const isAuthenticated = sessionStorage.getItem('admin-authenticated') === 'true';
        const timestamp = sessionStorage.getItem('admin-timestamp');
        const now = Date.now();
        const sessionTimeout = 24 * 60 * 60 * 1000; // 24 hours
        
        if (isAuthenticated && timestamp && (now - timestamp < sessionTimeout)) {
            window.location.href = '/index.html';
        } else {
            window.location.href = '/login.html';
        }
    </script>
</head>
<body>
    <p>Redirecting...</p>
</body>
</html>
EOF

echo ""
echo "✅ Simple authentication setup complete!"
echo ""
echo "🔐 Authentication Details:"
echo "   Username: admin"
echo "   Password: CHEQZvqKHsh9EyKv4ict"
echo "   Session Timeout: 24 hours"
echo ""
echo "📁 Files created/updated:"
echo "   - admin/login.html (login page)"
echo "   - admin/auth-check.js (authentication script)"
echo "   - admin/redirect.html (root redirect)"
echo "   - admin/index.html (updated with auth check)"
echo "   - admin/client-deployment.html (updated with auth check)"
echo ""
echo "🚀 Next steps:"
echo "1. Upload the updated admin files:"
echo "   aws s3 sync ./admin s3://\$(cd terraform && terraform output -raw admin_bucket) --delete"
echo ""
echo "2. Test the authentication:"
echo "   - Visit: https://admin.robertconsulting.net/"
echo "   - You'll be redirected to login page"
echo "   - Use credentials: admin / CHEQZvqKHsh9EyKv4ict"
echo ""
echo "💡 This is a client-side authentication solution."
echo "   For production use, consider server-side validation."
