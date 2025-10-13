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
    Generate CloudFront signed URLs for staging access
    """
    try:
        # Parse request body
        body = json.loads(event.get('body', '{}'))
        requested_path = body.get('path', '/')
        expiration_hours = body.get('expiration_hours', 24)
        
        # CloudFront configuration
        distribution_id = 'E23HB5TWK5BF44'  # Staging distribution ID
        key_pair_id = 'K2JCJMDEHXQW47'      # CloudFront key pair ID
        private_key = get_private_key()
        
        # Generate signed URL
        signed_url = generate_signed_url(
            distribution_id=distribution_id,
            key_pair_id=key_pair_id,
            private_key=private_key,
            url=f"https://staging.robertconsulting.net{requested_path}",
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

def get_private_key():
    """
    Get the private key for CloudFront signing
    This should be stored securely (e.g., in AWS Secrets Manager)
    """
    # For now, return a placeholder - in production, fetch from Secrets Manager
    return """
-----BEGIN RSA PRIVATE KEY-----
[PRIVATE_KEY_CONTENT_HERE]
-----END RSA PRIVATE KEY-----
"""

def generate_signed_url(distribution_id, key_pair_id, private_key, url, expiration_hours=24):
    """
    Generate a CloudFront signed URL
    """
    # Calculate expiration time
    expiration = int(time.time()) + (expiration_hours * 3600)
    
    # Create policy
    policy = {
        "Statement": [
            {
                "Resource": url,
                "Condition": {
                    "DateLessThan": {
                        "AWS:EpochTime": expiration
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
    # This is a simplified version - in production, use proper RSA signing
    # For now, return a placeholder signature
    return "SIGNATURE_PLACEHOLDER"
