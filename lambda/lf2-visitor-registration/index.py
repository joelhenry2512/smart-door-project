"""
LF2 - Visitor Registration Lambda Function
Handles owner approval workflow for unknown visitors
Registers new visitors in Rekognition and DynamoDB
"""

import json
import os
import boto3
import random
import string
import time
from datetime import datetime, timezone
from decimal import Decimal
from botocore.exceptions import ClientError

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')
sns_client = boto3.client('sns')
rekognition = boto3.client('rekognition')

# Environment variables
VISITORS_TABLE = os.environ.get('VISITORS_TABLE', 'smartdoor-visitors-dev')
PASSCODES_TABLE = os.environ.get('PASSCODES_TABLE', 'smartdoor-passcodes-dev')
PHOTOS_BUCKET = os.environ.get('PHOTOS_BUCKET', 'smartdoor-visitor-photos')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
COLLECTION_ID = os.environ.get('COLLECTION_ID', 'smartdoor-faces-dev')

# OTP Configuration
OTP_LENGTH = 6
OTP_TTL_SECONDS = 300  # 5 minutes

# Tables
visitors_table = dynamodb.Table(VISITORS_TABLE)
passcodes_table = dynamodb.Table(PASSCODES_TABLE)


def lambda_handler(event, context):
    """
    Handle POST /visitor requests from WP1 (Owner Approval Page)
    Expected body:
    {
        "faceId": "pending_xxx" or null,
        "name": "John Doe",
        "phoneNumber": "+12025551234",
        "photoKey": "visitors/xxx.jpg"
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
        
        # Validate required fields
        name = body.get('name')
        phone_number = body.get('phoneNumber')
        photo_key = body.get('photoKey')
        pending_face_id = body.get('faceId')
        
        if not name or not phone_number:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({
                    'error': 'Missing required fields: name and phoneNumber are required'
                })
            }
        
        # Validate phone number format (E.164)
        if not phone_number.startswith('+'):
            phone_number = '+1' + phone_number.replace('-', '').replace(' ', '')
        
        print(f"Registering visitor: {name}, {phone_number}")
        
        # Index face in Rekognition (if photo available)
        face_id = None
        if photo_key:
            face_id = index_face_in_rekognition(photo_key)
        
        if not face_id:
            # Generate a UUID-like face ID if indexing failed
            face_id = f"manual_{int(time.time() * 1000)}"
            print(f"Using generated face ID: {face_id}")
        
        # Create visitor record in DynamoDB
        visitor_record = create_visitor_record(face_id, name, phone_number, photo_key)
        
        # Clean up pending record if it exists
        if pending_face_id and pending_face_id.startswith('pending_'):
            try:
                visitors_table.delete_item(Key={'faceId': pending_face_id})
                print(f"Deleted pending record: {pending_face_id}")
            except Exception as e:
                print(f"Error deleting pending record: {str(e)}")
        
        # Generate and store OTP
        otp = generate_otp()
        store_otp(otp, face_id, name)
        
        # Send OTP to new visitor via SMS
        message = f"Hello {name}! You've been approved for Smart Door access.\nYour access code is: {otp}\nThis code expires in 5 minutes."
        send_sms(phone_number, message)
        
        # Notify owner of successful registration (optional)
        if SNS_TOPIC_ARN:
            try:
                sns_client.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject="Smart Door: New Visitor Registered",
                    Message=f"New visitor registered:\nName: {name}\nPhone: {phone_number}\nFace ID: {face_id}"
                )
            except Exception as e:
                print(f"Error sending notification: {str(e)}")
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'message': 'Visitor registered successfully',
                'faceId': face_id,
                'name': name,
                'otpSent': True
            })
        }
        
    except json.JSONDecodeError as e:
        print(f"JSON decode error: {str(e)}")
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({'error': 'Invalid JSON in request body'})
        }
    except Exception as e:
        print(f"Error processing request: {str(e)}")
        import traceback
        traceback.print_exc()
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': f'Internal server error: {str(e)}'})
        }


def index_face_in_rekognition(photo_key: str) -> str:
    """
    Index a face image in Rekognition collection
    Returns the FaceId if successful, None otherwise
    """
    try:
        # Ensure collection exists
        ensure_collection_exists()
        
        # Index face from S3
        response = rekognition.index_faces(
            CollectionId=COLLECTION_ID,
            Image={
                'S3Object': {
                    'Bucket': PHOTOS_BUCKET,
                    'Name': photo_key
                }
            },
            MaxFaces=1,
            QualityFilter='AUTO',
            DetectionAttributes=['ALL']
        )
        
        if response['FaceRecords']:
            face_id = response['FaceRecords'][0]['Face']['FaceId']
            print(f"Face indexed successfully: {face_id}")
            return face_id
        else:
            print("No face detected in image")
            return None
            
    except rekognition.exceptions.InvalidS3ObjectException as e:
        print(f"Invalid S3 object: {str(e)}")
        return None
    except rekognition.exceptions.InvalidImageFormatException as e:
        print(f"Invalid image format: {str(e)}")
        return None
    except Exception as e:
        print(f"Error indexing face: {str(e)}")
        return None


def ensure_collection_exists():
    """
    Create Rekognition collection if it doesn't exist
    """
    try:
        rekognition.create_collection(CollectionId=COLLECTION_ID)
        print(f"Created collection: {COLLECTION_ID}")
    except rekognition.exceptions.ResourceAlreadyExistsException:
        print(f"Collection already exists: {COLLECTION_ID}")
    except Exception as e:
        print(f"Error creating collection: {str(e)}")


def create_visitor_record(face_id: str, name: str, phone_number: str, photo_key: str) -> dict:
    """
    Create or update visitor record in DynamoDB
    """
    timestamp = datetime.now(timezone.utc).isoformat()
    
    # Build photo object
    photo_record = None
    if photo_key:
        photo_record = {
            'objectKey': photo_key,
            'bucket': PHOTOS_BUCKET,
            'createdTimestamp': timestamp
        }
    
    # Check if visitor exists (update) or is new (create)
    try:
        existing = visitors_table.get_item(Key={'faceId': face_id})
        if 'Item' in existing:
            # Update existing record - append new photo
            photos = existing['Item'].get('photos', [])
            if photo_record:
                photos.append(photo_record)
            
            visitors_table.update_item(
                Key={'faceId': face_id},
                UpdateExpression='SET #name = :name, phoneNumber = :phone, photos = :photos, updatedAt = :updated',
                ExpressionAttributeNames={'#name': 'name'},
                ExpressionAttributeValues={
                    ':name': name,
                    ':phone': phone_number,
                    ':photos': photos,
                    ':updated': timestamp
                }
            )
            print(f"Updated existing visitor: {face_id}")
            return existing['Item']
    except Exception as e:
        print(f"Error checking existing visitor: {str(e)}")
    
    # Create new record
    visitor_record = {
        'faceId': face_id,
        'name': name,
        'phoneNumber': phone_number,
        'photos': [photo_record] if photo_record else [],
        'createdAt': timestamp,
        'status': 'approved'
    }
    
    visitors_table.put_item(Item=visitor_record)
    print(f"Created new visitor record: {face_id}")
    
    return visitor_record


def generate_otp() -> str:
    """
    Generate a random 6-digit OTP
    """
    return ''.join(random.choices(string.digits, k=OTP_LENGTH))


def store_otp(otp: str, face_id: str, visitor_name: str):
    """
    Store OTP in DynamoDB with TTL
    """
    ttl = int(time.time()) + OTP_TTL_SECONDS
    
    passcodes_table.put_item(
        Item={
            'otp': otp,
            'faceId': face_id,
            'visitorName': visitor_name,
            'createdAt': datetime.now(timezone.utc).isoformat(),
            'ttl': ttl
        }
    )
    print(f"OTP {otp} stored with TTL {ttl}")


def send_sms(phone_number: str, message: str):
    """
    Send SMS using SNS
    """
    try:
        response = sns_client.publish(
            PhoneNumber=phone_number,
            Message=message,
            MessageAttributes={
                'AWS.SNS.SMS.SMSType': {
                    'DataType': 'String',
                    'StringValue': 'Transactional'
                }
            }
        )
        print(f"SMS sent to {phone_number}: MessageId={response['MessageId']}")
        return response
    except Exception as e:
        print(f"Error sending SMS to {phone_number}: {str(e)}")
        raise


# For local testing
if __name__ == "__main__":
    # Test event simulating API Gateway
    test_event = {
        'body': json.dumps({
            'name': 'John Doe',
            'phoneNumber': '+12025551234',
            'photoKey': 'visitors/test.jpg',
            'faceId': 'pending_12345'
        }),
        'httpMethod': 'POST',
        'path': '/visitor'
    }
    
    result = lambda_handler(test_event, None)
    print(f"Result: {json.dumps(result, indent=2)}")
