import json
import os
import hashlib
import time
from datetime import datetime, timedelta

def handler(event, context):
    """
    Generate access tokens for staging environment
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        requested_path = body.get('path', '/')
        expiration_hours = body.get('expiration_hours', 24)
        
        # Get staging access token from environment
        staging_token = os.environ.get('STAGING_ACCESS_TOKEN', 'staging-access-2025')
        
        # Generate access token
        access_token = generate_access_token(
            path=requested_path,
            expiration_hours=expiration_hours,
            secret=staging_token
        )
        
        # Create staging URL with token
        staging_url = f"https://staging.robertconsulting.net{requested_path}?token={access_token}"
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'staging_url': staging_url,
                'access_token': access_token,
                'expires_at': (datetime.utcnow() + timedelta(hours=expiration_hours)).isoformat(),
                'path': requested_path
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e)
            })
        }

def generate_access_token(path, expiration_hours, secret):
    """
    Generate a simple access token for staging
    """
    # Calculate expiration timestamp
    expiration = int(time.time()) + (expiration_hours * 3600)
    
    # Create token data
    token_data = f"{path}:{expiration}:{secret}"
    
    # Generate hash
    token_hash = hashlib.sha256(token_data.encode()).hexdigest()
    
    # Create token (path:expiration:hash)
    access_token = f"{path}:{expiration}:{token_hash}"
    
    # Base64 encode for URL safety
    import base64
    encoded_token = base64.b64encode(access_token.encode()).decode()
    
    return encoded_token
