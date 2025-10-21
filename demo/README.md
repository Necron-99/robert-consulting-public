# Demo Scripts Directory

This directory contains demonstration scripts with obfuscated credentials for educational and testing purposes.

## ⚠️ WARNING

**DO NOT USE IN PRODUCTION ENVIRONMENTS**

These scripts contain obfuscated credentials that are:
- Not secure for production use
- Intended for demonstration purposes only
- Should be used only in isolated testing environments

## Contents

### Scripts

- `scripts/setup-simple-auth-demo.sh` - Demo authentication setup with obfuscated password

## Security Notes

1. **Obfuscated Credentials**: Passwords are base64 encoded but not encrypted
2. **Client-Side Authentication**: These demos use client-side validation (insecure)
3. **Session Management**: Basic session storage (not secure for production)

## How to Decode Obfuscated Passwords

To decode the base64 obfuscated password:

```bash
echo "Q0hFUVp2cUtIc2g5RXlLdjRpY3QK" | base64 -d
```

## Production Recommendations

For production environments, use:
- Server-side authentication
- Proper session management
- Secure credential storage
- HTTPS and security headers
- Multi-factor authentication
- Regular security audits

## Usage

These scripts are for demonstration purposes only. They show:
- Basic authentication flow
- Session management concepts
- Security considerations
- Implementation patterns

Do not deploy these scripts to production systems.
