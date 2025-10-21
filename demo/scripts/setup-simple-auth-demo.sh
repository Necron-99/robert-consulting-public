#!/bin/bash
# DEMO: Simple authentication setup using a basic HTML login page
# WARNING: This is a demonstration script with obfuscated credentials
# DO NOT use in production environments

set -e

echo "🔐 DEMO: Setting up simple authentication for admin site..."
echo "⚠️  WARNING: This is a demonstration script with obfuscated credentials"

# Obfuscated password (base64 encoded)
# Original: CHEQZvqKHsh9EyKv4ict
# Decode with: echo "Q0hFUVp2cUtIc2g5RXlLdjRpY3QK" | base64 -d
OBFUSCATED_PASSWORD="Q0hFUVp2cUtIc2g5RXlLdjRpY3QK"

# Create a simple login page
echo "📝 Creating demo login page..."
cat > admin/login-demo.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Login - Robert Consulting (DEMO)</title>
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
        .demo-warning {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            color: #856404;
            padding: 1rem;
            border-radius: 5px;
            margin-bottom: 1rem;
            text-align: center;
            font-size: 0.9rem;
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
            <h1>🔐 Admin Access (DEMO)</h1>
            <p>Robert Consulting Admin Portal</p>
        </div>
        
        <div class="demo-warning">
            ⚠️ This is a demonstration version with obfuscated credentials
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
            
            <button type="submit" class="login-btn">Login (DEMO)</button>
            
            <div class="error" id="error">Invalid credentials. Please try again.</div>
        </form>
        
        <div class="footer">
            <p>DEMO: Secure access to admin functions</p>
        </div>
    </div>

    <script>
        // Obfuscated password (base64 encoded)
        const OBFUSCATED_PASSWORD = "Q0hFUVp2cUtIc2g5RXlLdjRpY3QK";
        
        // Function to decode base64
        function decodeBase64(str) {
            return atob(str.trim());
        }
        
        document.getElementById('loginForm').addEventListener('submit', function(e) {
            e.preventDefault();
            
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            
            // Decode the obfuscated password for comparison
            const decodedPassword = decodeBase64(OBFUSCATED_PASSWORD);
            
            // Simple client-side authentication (for demo purposes)
            // In production, this should be server-side validation
            if (username === 'admin' && password === decodedPassword) {
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

echo ""
echo "✅ DEMO: Simple authentication setup complete!"
echo ""
echo "🔐 DEMO Authentication Details:"
echo "   Username: admin"
echo "   Password: [OBFUSCATED - base64 encoded]"
echo "   Decode with: echo 'Q0hFUVp2cUtIc2g5RXlLdjRpY3QK' | base64 -d"
echo "   Session Timeout: 24 hours"
echo ""
echo "📁 DEMO Files created:"
echo "   - admin/login-demo.html (demo login page)"
echo ""
echo "⚠️  WARNING: This is a demonstration script!"
echo "   - Credentials are obfuscated but not secure"
echo "   - Do not use in production environments"
echo "   - For production, use proper server-side authentication"
echo ""
echo "🚀 DEMO Testing:"
echo "1. Open admin/login-demo.html in a browser"
echo "2. Use credentials: admin / [decoded password]"
echo "3. This demonstrates the authentication flow"
echo ""
echo "💡 For production use:"
echo "   - Implement server-side validation"
echo "   - Use proper session management"
echo "   - Store credentials securely"
echo "   - Use HTTPS and secure headers"
