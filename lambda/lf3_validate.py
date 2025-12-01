"""
LF3: OTP Validation API
Validates passcodes entered on virtual door (WP2)
"""
import json
import boto3
import os
import time
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
PASSCODES_TABLE = os.environ.get('PASSCODES_TABLE')


def handler(event, context):
    print(f"Event: {json.dumps(event)}")
    
    if event.get('httpMethod') == 'OPTIONS':
        return response(200, {})
    
    try:
        body = json.loads(event.get('body', '{}'))
        otp = body.get('otp', '').strip()
        
        if not otp:
            return response(400, {'valid': False, 'message': 'OTP required'})
        
        result = validate_otp(otp)
        
        if result['valid']:
            return response(200, {
                'valid': True,
                'message': f"Welcome, {result['name']}! Access granted.",
                'visitorName': result['name']
            })
        else:
            return response(403, {
                'valid': False,
                'message': 'Permission denied. Invalid or expired OTP.'
            })
            
    except Exception as e:
        print(f"Error: {e}")
        return response(500, {'valid': False, 'message': str(e)})


def validate_otp(otp):
    passcodes = dynamodb.Table(PASSCODES_TABLE)
    now = int(time.time())
    
    resp = passcodes.get_item(Key={'otp': otp})
    
    if 'Item' not in resp:
        return {'valid': False}
    
    item = resp['Item']
    ttl = item.get('ttl', 0)
    
    # Check expiration
    if now > ttl:
        passcodes.delete_item(Key={'otp': otp})
        return {'valid': False}
    
    name = item.get('visitorName', 'Visitor')
    
    # Delete used OTP (one-time use)
    passcodes.delete_item(Key={'otp': otp})
    
    # Log access
    print(f"ACCESS GRANTED: {datetime.utcnow().isoformat()} - {name}")
    
    return {'valid': True, 'name': name}


def response(code, body):
    return {
        'statusCode': code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps(body)
    }
