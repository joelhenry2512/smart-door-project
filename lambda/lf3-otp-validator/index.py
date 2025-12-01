"""
LF3 - OTP Validator Lambda Function
Validates one-time passcodes for door access
"""

import json
import os
import boto3
import time
from datetime import datetime, timezone
from decimal import Decimal

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')

# Environment variables
PASSCODES_TABLE = os.environ.get('PASSCODES_TABLE', 'smartdoor-passcodes-dev')

# Table
passcodes_table = dynamodb.Table(PASSCODES_TABLE)


def lambda_handler(event, context):
    """
    Handle POST /validate requests from WP2 (Virtual Door Page)
    Expected body:
    {
        "otp": "123456"
    }
    """
    print(f"Received event: {json.dumps(event, default=str)}")
    
    # CORS headers
    headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key',
        'Access-Control-Allow-Methods': 'POST,OPTIONS'
    }
    
    try:
        # Parse request body
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', {})
        
        # Extract OTP
        otp = body.get('otp', '').strip()
        
        if not otp:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'access': 'denied',
                    'message': 'OTP is required'
                })
            }
        
        # Validate OTP length
        if len(otp) != 6 or not otp.isdigit():
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'access': 'denied',
                    'message': 'Invalid OTP format. Please enter a 6-digit code.'
                })
            }
        
        print(f"Validating OTP: {otp}")
        
        # Look up OTP in DynamoDB
        response = passcodes_table.get_item(Key={'otp': otp})
        
        if 'Item' not in response:
            print(f"OTP not found: {otp}")
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({
                    'access': 'denied',
                    'message': 'Invalid OTP. Please check your code and try again.'
                })
            }
        
        item = response['Item']
        
        # Check if OTP has expired (TTL)
        ttl = int(item.get('ttl', 0))
        current_time = int(time.time())
        
        if current_time > ttl:
            print(f"OTP expired: {otp} (TTL: {ttl}, Current: {current_time})")
            # Delete expired OTP
            try:
                passcodes_table.delete_item(Key={'otp': otp})
            except Exception as e:
                print(f"Error deleting expired OTP: {str(e)}")
            
            return {
                'statusCode': 401,
                'headers': headers,
                'body': json.dumps({
                    'access': 'denied',
                    'message': 'OTP has expired. Please request a new code.'
                })
            }
        
        # OTP is valid - grant access
        visitor_name = item.get('visitorName', 'Visitor')
        face_id = item.get('faceId', 'unknown')
        
        print(f"Access granted to {visitor_name} (faceId: {face_id})")
        
        # Delete used OTP (one-time use)
        try:
            passcodes_table.delete_item(Key={'otp': otp})
            print(f"Deleted used OTP: {otp}")
        except Exception as e:
            print(f"Error deleting used OTP: {str(e)}")
        
        # Calculate remaining time for display
        time_remaining = ttl - current_time
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'access': 'granted',
                'message': f'Welcome, {visitor_name}! Door is now unlocked.',
                'visitorName': visitor_name,
                'faceId': face_id,
                'timestamp': datetime.now(timezone.utc).isoformat()
            })
        }
        
    except json.JSONDecodeError as e:
        print(f"JSON decode error: {str(e)}")
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({
                'access': 'denied',
                'message': 'Invalid request format'
            })
        }
    except Exception as e:
        print(f"Error processing request: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({
                'access': 'denied',
                'message': 'An error occurred. Please try again.'
            })
        }


# Helper function for testing - add a test OTP
def add_test_otp(otp: str, visitor_name: str = "Test Visitor", ttl_seconds: int = 300):
    """
    Add a test OTP to the table (for testing purposes)
    """
    ttl = int(time.time()) + ttl_seconds
    
    passcodes_table.put_item(
        Item={
            'otp': otp,
            'faceId': 'test-face-id',
            'visitorName': visitor_name,
            'createdAt': datetime.now(timezone.utc).isoformat(),
            'ttl': ttl
        }
    )
    print(f"Test OTP added: {otp} (expires in {ttl_seconds}s)")


# For local testing
if __name__ == "__main__":
    # Test cases
    test_cases = [
        # Valid OTP (would need to be added to DB first)
        {'body': json.dumps({'otp': '123456'})},
        # Invalid format
        {'body': json.dumps({'otp': 'abc'})},
        # Missing OTP
        {'body': json.dumps({})},
        # Empty OTP
        {'body': json.dumps({'otp': ''})},
    ]
    
    for i, test_event in enumerate(test_cases):
        print(f"\n--- Test Case {i + 1} ---")
        result = lambda_handler(test_event, None)
        print(f"Status: {result['statusCode']}")
        print(f"Body: {result['body']}")
