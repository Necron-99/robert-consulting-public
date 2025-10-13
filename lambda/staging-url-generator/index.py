import json
import boto3
import base64
import hashlib
import hmac
import time
from datetime import datetime, timedelta
from urllib.parse import quote

def handler(event, context):
    """
    Generate CloudFront signed URLs for staging environment access
    """
    try:
        # Parse the request
        body = json.loads(event.get('body', '{}'))
        requested_path = body.get('path', '/')
        expiration_hours = body.get('expiration_hours', 24)
        
        # Get CloudFront key pair from environment
        key_pair_id = 'K2JCJMDEHXQW47'  # CloudFront key pair ID
        private_key = get_private_key()
        
        # Generate signed URL
        signed_url = generate_signed_url(
            url=f"https://staging.robertconsulting.net{requested_path}",
            key_pair_id=key_pair_id,
            private_key=private_key,
            expiration_hours=expiration_hours
        )
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'signed_url': signed_url,
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

def get_private_key():
    """
    Get CloudFront private key from Secrets Manager
    """
    secrets_client = boto3.client('secretsmanager')
    try:
        response = secrets_client.get_secret_value(SecretId='cloudfront-staging-private-key')
        return response['SecretString']
    except Exception as e:
        # Fallback to environment variable for development
        import os
        return os.environ.get('CLOUDFRONT_PRIVATE_KEY', '')

def generate_signed_url(url, key_pair_id, private_key, expiration_hours=24):
    """
    Generate CloudFront signed URL
    """
    # Calculate expiration time
    expires = int(time.time()) + (expiration_hours * 3600)
    
    # Create policy
    policy = {
        "Statement": [
            {
                "Resource": url,
                "Condition": {
                    "DateLessThan": {
                        "AWS:EpochTime": expires
                    }
                }
            }
        ]
    }
    
    # Encode policy
    policy_json = json.dumps(policy, separators=(',', ':'))
    policy_b64 = base64.b64encode(policy_json.encode('utf-8')).decode('utf-8')
    
    # Sign policy
    signature = sign_policy(policy_b64, private_key)
    
    # Create signed URL
    signed_url = f"{url}?Policy={policy_b64}&Signature={signature}&Key-Pair-Id={key_pair_id}"
    
    return signed_url

def sign_policy(policy, private_key):
    """
    Sign the policy with the private key
    """
    # Decode private key
    private_key_pem = private_key.replace('\\n', '\n')
    
    # Sign the policy
    signature = hmac.new(
        private_key_pem.encode('utf-8'),
        policy.encode('utf-8'),
        hashlib.sha1
    ).digest()
    
    # Encode signature
    signature_b64 = base64.b64encode(signature).decode('utf-8')
    
    return signature_b64