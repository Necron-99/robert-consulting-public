import json
import boto3
import jwt
import time
from datetime import datetime, timedelta

def handler(event, context):
    """
    Generate JWT tokens for staging environment access
    """
    try:
        # Parse the request
        body = json.loads(event.get('body', '{}'))
        requested_path = body.get('path', '/')
        expiration_hours = body.get('expiration_hours', 24)
        
        # Get JWT secret from environment
        jwt_secret = get_jwt_secret()
        
        # Generate JWT token
        token = generate_jwt_token(
            path=requested_path,
            expiration_hours=expiration_hours,
            secret=jwt_secret
        )
        
        # Create staging URL with token
        staging_url = f"https://staging.robertconsulting.net{requested_path}?token={token}"
        
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
                'token': token,
                'expires_at': (datetime.utcnow() + timedelta(hours=expiration_hours)).isoformat(),
                'expiration_hours': expiration_hours
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

def get_jwt_secret():
    """
    Get JWT secret from Secrets Manager
    """
    secrets_client = boto3.client('secretsmanager')
    try:
        response = secrets_client.get_secret_value(SecretId='staging-jwt-secret')
        return response['SecretString']
    except Exception as e:
        # Fallback to environment variable for development
        import os
        return os.environ.get('JWT_SECRET', 'staging-secret-2025')

def generate_jwt_token(path, expiration_hours, secret):
    """
    Generate JWT token for staging access
    """
    # Calculate expiration time
    expires = datetime.utcnow() + timedelta(hours=expiration_hours)
    
    # Create payload
    payload = {
        'path': path,
        'exp': expires,
        'iat': datetime.utcnow(),
        'iss': 'staging-access-control',
        'aud': 'staging.robertconsulting.net'
    }
    
    # Generate token
    token = jwt.encode(payload, secret, algorithm='HS256')
    
    return token