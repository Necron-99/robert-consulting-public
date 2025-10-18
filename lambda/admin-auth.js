// Enhanced Admin Authentication Lambda Function
// Handles MFA, session management, IP restrictions, and audit logging

const AWS = require('aws-sdk');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const speakeasy = require('speakeasy');

const secretsManager = new AWS.SecretsManager();
const dynamodb = new AWS.DynamoDB.DocumentClient();

// Configuration
const SECRETS_MANAGER_SECRET_ID = process.env.SECRETS_MANAGER_SECRET_ID;
const SESSIONS_TABLE_NAME = process.env.SESSIONS_TABLE_NAME;
const AUDIT_TABLE_NAME = process.env.AUDIT_TABLE_NAME;
const MFA_ENABLED = process.env.MFA_ENABLED === 'true';

let securityConfig = null;

// Cache security configuration
async function getSecurityConfig() {
  if (!securityConfig) {
    try {
      const result = await secretsManager.getSecretValue({
        SecretId: SECRETS_MANAGER_SECRET_ID
      }).promise();
      
      securityConfig = JSON.parse(result.SecretString);
    } catch (error) {
      console.error('Error retrieving security config:', error);
      throw new Error('Security configuration unavailable');
    }
  }
  return securityConfig;
}

// Generate secure session token
function generateSessionToken() {
  return crypto.randomBytes(32).toString('hex');
}

// Generate MFA secret for user
function generateMFASecret() {
  return speakeasy.generateSecret({
    name: 'Robert Consulting Admin',
    issuer: 'Robert Consulting'
  });
}

// Verify MFA token
function verifyMFAToken(token, secret) {
  return speakeasy.totp.verify({
    secret: secret,
    encoding: 'base32',
    token: token,
    window: 2
  });
}

// Check if IP is allowed
function isIPAllowed(clientIP, allowedIPs) {
  if (!allowedIPs || allowedIPs.length === 0) {
    return true; // No IP restrictions
  }
  
  return allowedIPs.some(allowedIP => {
    if (allowedIP.includes('/')) {
      // CIDR notation
      return isIPInCIDR(clientIP, allowedIP);
    } else {
      // Single IP
      return clientIP === allowedIP;
    }
  });
}

// Simple CIDR check (for basic use cases)
function isIPInCIDR(ip, cidr) {
  const [network, prefixLength] = cidr.split('/');
  const ipNum = ipToNumber(ip);
  const networkNum = ipToNumber(network);
  const mask = (0xffffffff << (32 - parseInt(prefixLength))) >>> 0;
  
  return (ipNum & mask) === (networkNum & mask);
}

function ipToNumber(ip) {
  return ip.split('.').reduce((acc, octet) => (acc << 8) + parseInt(octet), 0) >>> 0;
}

// Log audit event
async function logAuditEvent(eventType, details, clientIP, userAgent) {
  try {
    const timestamp = new Date().toISOString();
    const actionId = crypto.randomUUID();
    
    await dynamodb.put({
      TableName: AUDIT_TABLE_NAME,
      Item: {
        timestamp: timestamp,
        action_id: actionId,
        action_type: eventType,
        user_ip: clientIP,
        user_agent: userAgent,
        details: JSON.stringify(details),
        expires_at: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60) // 1 year
      }
    }).promise();
  } catch (error) {
    console.error('Error logging audit event:', error);
  }
}

// Check for brute force attempts
async function checkBruteForceAttempts(clientIP) {
  try {
    const config = await getSecurityConfig();
    const cutoffTime = new Date(Date.now() - (config.lockout_duration * 60 * 1000));
    
    const result = await dynamodb.query({
      TableName: AUDIT_TABLE_NAME,
      IndexName: 'user-ip-index',
      KeyConditionExpression: 'user_ip = :ip',
      FilterExpression: 'action_type = :type AND #timestamp > :cutoff',
      ExpressionAttributeNames: {
        '#timestamp': 'timestamp'
      },
      ExpressionAttributeValues: {
        ':ip': clientIP,
        ':type': 'LOGIN_FAILED',
        ':cutoff': cutoffTime.toISOString()
      }
    }).promise();
    
    return result.Items.length >= config.max_login_attempts;
  } catch (error) {
    console.error('Error checking brute force attempts:', error);
    return false;
  }
}

// Create session
async function createSession(clientIP, userAgent) {
  try {
    const config = await getSecurityConfig();
    const sessionToken = generateSessionToken();
    const expiresAt = Math.floor(Date.now() / 1000) + (config.session_timeout * 60);
    
    await dynamodb.put({
      TableName: SESSIONS_TABLE_NAME,
      Item: {
        session_id: sessionToken,
        created_at: new Date().toISOString(),
        user_ip: clientIP,
        user_agent: userAgent,
        expires_at: expiresAt,
        last_activity: new Date().toISOString()
      }
    }).promise();
    
    return sessionToken;
  } catch (error) {
    console.error('Error creating session:', error);
    throw new Error('Session creation failed');
  }
}

// Validate session
async function validateSession(sessionToken, clientIP) {
  try {
    const result = await dynamodb.get({
      TableName: SESSIONS_TABLE_NAME,
      Key: {
        session_id: sessionToken,
        created_at: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString() }
      }
    }).promise();
    
    if (!result.Item) {
      return false;
    }
    
    // Check if session is expired
    if (Date.now() / 1000 > result.Item.expires_at) {
      await dynamodb.delete({
        TableName: SESSIONS_TABLE_NAME,
        Key: {
          session_id: sessionToken,
          created_at: result.Item.created_at
        }
      }).promise();
      return false;
    }
    
    // Check IP match
    if (result.Item.user_ip !== clientIP) {
      await logAuditEvent('SESSION_IP_MISMATCH', {
        session_id: sessionToken,
        expected_ip: result.Item.user_ip,
        actual_ip: clientIP
      }, clientIP, '');
      return false;
    }
    
    // Update last activity
    await dynamodb.update({
      TableName: SESSIONS_TABLE_NAME,
      Key: {
        session_id: sessionToken,
        created_at: result.Item.created_at
      },
      UpdateExpression: 'SET last_activity = :activity',
      ExpressionAttributeValues: {
        ':activity': new Date().toISOString()
      }
    }).promise();
    
    return true;
  } catch (error) {
    console.error('Error validating session:', error);
    return false;
  }
}

// Main handler
exports.handler = async (event) => {
  const request = event.Records[0].cf.request;
  const headers = request.headers;
  const uri = request.uri;
  const method = request.method;
  
  // Extract client information
  const clientIP = headers['x-forwarded-for'] ? 
    headers['x-forwarded-for'][0].value.split(',')[0].trim() : 
    headers['cf-connecting-ip'] ? headers['cf-connecting-ip'][0].value : 'unknown';
  
  const userAgent = headers['user-agent'] ? headers['user-agent'][0].value : 'unknown';
  
  try {
    const config = await getSecurityConfig();
    
    // Check IP restrictions
    if (!isIPAllowed(clientIP, config.allowed_ips)) {
      await logAuditEvent('IP_BLOCKED', {
        client_ip: clientIP,
        allowed_ips: config.allowed_ips
      }, clientIP, userAgent);
      
      return {
        status: '403',
        statusDescription: 'Forbidden',
        headers: {
          'content-type': [{ key: 'Content-Type', value: 'text/plain' }]
        },
        body: 'Access denied: IP not allowed'
      };
    }
    
    // Skip authentication for static assets
    if (uri.match(/\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$/)) {
      return request;
    }
    
    // Handle login endpoint
    if (uri === '/admin-login' && method === 'POST') {
      return await handleLogin(request, clientIP, userAgent, config);
    }
    
    // Handle MFA verification
    if (uri === '/admin-mfa' && method === 'POST') {
      return await handleMFAVerification(request, clientIP, userAgent, config);
    }
    
    // Check for existing session
    const sessionCookie = getCookie(headers, 'admin-session');
    if (sessionCookie && await validateSession(sessionCookie, clientIP)) {
      return request;
    }
    
    // Redirect to login page
    return {
      status: '302',
      statusDescription: 'Found',
      headers: {
        'location': [{
          key: 'Location',
          value: '/admin-login.html'
        }],
        'cache-control': [{
          key: 'Cache-Control',
          value: 'no-cache, no-store, must-revalidate'
        }]
      }
    };
    
  } catch (error) {
    console.error('Authentication error:', error);
    
    await logAuditEvent('AUTH_ERROR', {
      error: error.message,
      uri: uri,
      method: method
    }, clientIP, userAgent);
    
    return {
      status: '500',
      statusDescription: 'Internal Server Error',
      headers: {
        'content-type': [{ key: 'Content-Type', value: 'text/plain' }]
      },
      body: 'Authentication service unavailable'
    };
  }
};

// Handle login
async function handleLogin(request, clientIP, userAgent, config) {
  try {
    // Check for brute force attempts
    if (await checkBruteForceAttempts(clientIP)) {
      await logAuditEvent('BRUTE_FORCE_BLOCKED', {
        client_ip: clientIP,
        lockout_duration: config.lockout_duration
      }, clientIP, userAgent);
      
      return {
        status: '429',
        statusDescription: 'Too Many Requests',
        headers: {
          'content-type': [{ key: 'Content-Type', value: 'application/json' }],
          'retry-after': [{ key: 'Retry-After', value: config.lockout_duration.toString() }]
        },
        body: JSON.stringify({
          error: 'Too many failed attempts',
          retry_after: config.lockout_duration
        })
      };
    }
    
    // Parse request body
    const body = Buffer.from(request.body.data, 'base64').toString();
    const credentials = JSON.parse(body);
    
    // Verify password
    const passwordValid = await bcrypt.compare(credentials.password, config.admin_password_hash);
    
    if (!passwordValid) {
      await logAuditEvent('LOGIN_FAILED', {
        reason: 'invalid_password',
        username: credentials.username
      }, clientIP, userAgent);
      
      return {
        status: '401',
        statusDescription: 'Unauthorized',
        headers: {
          'content-type': [{ key: 'Content-Type', value: 'application/json' }]
        },
        body: JSON.stringify({
          error: 'Invalid credentials',
          mfa_required: MFA_ENABLED
        })
      };
    }
    
    // If MFA is enabled, require MFA verification
    if (MFA_ENABLED) {
      await logAuditEvent('LOGIN_SUCCESS_PENDING_MFA', {
        username: credentials.username
      }, clientIP, userAgent);
      
      return {
        status: '200',
        statusDescription: 'OK',
        headers: {
          'content-type': [{ key: 'Content-Type', value: 'application/json' }]
        },
        body: JSON.stringify({
          success: true,
          mfa_required: true,
          message: 'MFA verification required'
        })
      };
    }
    
    // Create session
    const sessionToken = await createSession(clientIP, userAgent);
    
    await logAuditEvent('LOGIN_SUCCESS', {
      username: credentials.username,
      session_id: sessionToken
    }, clientIP, userAgent);
    
    return {
      status: '200',
      statusDescription: 'OK',
      headers: {
        'content-type': [{ key: 'Content-Type', value: 'application/json' }],
        'set-cookie': [{
          key: 'Set-Cookie',
          value: `admin-session=${sessionToken}; HttpOnly; Secure; SameSite=Strict; Max-Age=${config.session_timeout * 60}`
        }]
      },
      body: JSON.stringify({
        success: true,
        redirect: '/admin/'
      })
    };
    
  } catch (error) {
    console.error('Login error:', error);
    
    await logAuditEvent('LOGIN_ERROR', {
      error: error.message
    }, clientIP, userAgent);
    
    return {
      status: '500',
      statusDescription: 'Internal Server Error',
      headers: {
        'content-type': [{ key: 'Content-Type', value: 'application/json' }]
      },
      body: JSON.stringify({
        error: 'Login service unavailable'
      })
    };
  }
}

// Handle MFA verification
async function handleMFAVerification(request, clientIP, userAgent, config) {
  try {
    const body = Buffer.from(request.body.data, 'base64').toString();
    const mfaData = JSON.parse(body);
    
    // Verify MFA token
    const mfaValid = verifyMFAToken(mfaData.token, config.mfa_secret_key);
    
    if (!mfaValid) {
      await logAuditEvent('MFA_FAILED', {
        token: mfaData.token
      }, clientIP, userAgent);
      
      return {
        status: '401',
        statusDescription: 'Unauthorized',
        headers: {
          'content-type': [{ key: 'Content-Type', value: 'application/json' }]
        },
        body: JSON.stringify({
          error: 'Invalid MFA token'
        })
      };
    }
    
    // Create session
    const sessionToken = await createSession(clientIP, userAgent);
    
    await logAuditEvent('MFA_SUCCESS', {
      session_id: sessionToken
    }, clientIP, userAgent);
    
    return {
      status: '200',
      statusDescription: 'OK',
      headers: {
        'content-type': [{ key: 'Content-Type', value: 'application/json' }],
        'set-cookie': [{
          key: 'Set-Cookie',
          value: `admin-session=${sessionToken}; HttpOnly; Secure; SameSite=Strict; Max-Age=${config.session_timeout * 60}`
        }]
      },
      body: JSON.stringify({
        success: true,
        redirect: '/admin/'
      })
    };
    
  } catch (error) {
    console.error('MFA verification error:', error);
    
    await logAuditEvent('MFA_ERROR', {
      error: error.message
    }, clientIP, userAgent);
    
    return {
      status: '500',
      statusDescription: 'Internal Server Error',
      headers: {
        'content-type': [{ key: 'Content-Type', value: 'application/json' }]
      },
      body: JSON.stringify({
        error: 'MFA service unavailable'
      })
    };
  }
}

// Helper function to get cookie value
function getCookie(headers, name) {
  const cookieHeader = headers.cookie;
  if (!cookieHeader) return null;
  
  const cookies = cookieHeader[0].value.split(';');
  for (const cookie of cookies) {
    const [key, value] = cookie.trim().split('=');
    if (key === name) {
      return value;
    }
  }
  return null;
}
