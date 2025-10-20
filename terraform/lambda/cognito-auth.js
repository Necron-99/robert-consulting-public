// Lambda@Edge function for Cognito authentication
// This function handles authentication for the admin site

const https = require('https');
const querystring = require('querystring');

// Configuration from Terraform
const USER_POOL_ID = '${user_pool_id}';
const USER_POOL_CLIENT_ID = '${user_pool_client}';
const ADMIN_DOMAIN = '${admin_domain}';

// Cognito endpoints
const COGNITO_DOMAIN = `https://rc-admin-${USER_POOL_ID.split('_')[1]}.auth.us-east-1.amazoncognito.com`;

exports.handler = async(event) => {
    const request = event.Records[0].cf.request;
    const headers = request.headers;
    
    // Skip authentication for static assets and callback URLs
    const uri = request.uri;
    if (uri.startsWith('/callback') || 
        uri.startsWith('/logout') || 
        uri.startsWith('/static/') ||
        uri.match(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$/)) {
        return request;
    }
    
    // Check for existing session cookie
    const sessionCookie = getCookie(headers, 'admin-session');
    if (sessionCookie && await validateSession(sessionCookie)) {
        return request;
    }
    
    // Check for authorization code in callback
    if (uri.startsWith('/callback')) {
        return handleCallback(request);
    }
    
    // Redirect to Cognito login
    return {
        status: '302',
        statusDescription: 'Found',
        headers: {
            location: [{
                key: 'Location',
                value: `${COGNITO_DOMAIN}/login?client_id=${USER_POOL_CLIENT_ID}&response_type=code&scope=email+openid+profile&redirect_uri=https://${ADMIN_DOMAIN}/callback`
            }],
            'cache-control': [{
                key: 'Cache-Control',
                value: 'no-cache, no-store, must-revalidate'
            }]
        }
    };
};

function getCookie(headers, name) {
    const cookieHeader = headers.cookie;
    if (!cookieHeader) return null;
    
    const cookies = cookieHeader[0].value.split(';');
    for (const cookie of cookies) {
        const [key, value] = cookie.trim().split('=');
        if (key === name) return value;
    }
    return null;
}

async function validateSession(sessionToken) {
    try {
        // In a real implementation, you would validate the JWT token
        // For now, we'll do a simple check
        return sessionToken && sessionToken.length > 10;
    } catch (error) {
        console.error('Session validation error:', error);
        return false;
    }
}

async function handleCallback(request) {
    const queryString = request.querystring;
    const params = querystring.parse(queryString);
    
    if (params.code) {
        try {
            // Exchange authorization code for tokens
            const tokens = await exchangeCodeForTokens(params.code);
            
            // Set session cookie and redirect to admin
            return {
                status: '302',
                statusDescription: 'Found',
                headers: {
                    location: [{
                        key: 'Location',
                        value: `https://${ADMIN_DOMAIN}/`
                    }],
                    'set-cookie': [{
                        key: 'Set-Cookie',
                        value: `admin-session=${tokens.access_token}; HttpOnly; Secure; SameSite=Strict; Max-Age=3600`
                    }]
                }
            };
        } catch (error) {
            console.error('Token exchange error:', error);
            return createErrorResponse('Authentication failed');
        }
    }
    
    return createErrorResponse('Invalid callback');
}

async function exchangeCodeForTokens(code) {
    return new Promise((resolve, reject) => {
        const postData = querystring.stringify({
            // eslint-disable-next-line camelcase
            grant_type: 'authorization_code',
            // eslint-disable-next-line camelcase
            client_id: USER_POOL_CLIENT_ID,
            code: code,
            // eslint-disable-next-line camelcase
            redirect_uri: `https://${ADMIN_DOMAIN}/callback`
        });
        
        const options = {
            hostname: 'rc-admin-' + USER_POOL_ID.split('_')[1] + '.auth.us-east-1.amazoncognito.com',
            port: 443,
            path: '/oauth2/token',
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Content-Length': Buffer.byteLength(postData)
            }
        };
        
        const req = https.request(options, (res) => {
            let data = '';
            res.on('data', (chunk) => {
                data += chunk;
            });
            res.on('end', () => {
                try {
                    const tokens = JSON.parse(data);
                    resolve(tokens);
                } catch (error) {
                    reject(error);
                }
            });
        });
        
        req.on('error', reject);
        req.write(postData);
        req.end();
    });
}

function createErrorResponse(message) {
    return {
        status: '401',
        statusDescription: 'Unauthorized',
        headers: {
            'content-type': [{
                key: 'Content-Type',
                value: 'text/html'
            }]
        },
        body: `
            <!DOCTYPE html>
            <html>
            <head>
                <title>Authentication Error</title>
                <style>
                    body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
                    .error { color: #d32f2f; }
                </style>
            </head>
            <body>
                <h1 class="error">Authentication Error</h1>
                <p>${message}</p>
                <a href="/">Try Again</a>
            </body>
            </html>
        `
    };
}
