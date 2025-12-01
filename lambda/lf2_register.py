"""
LF2: Visitor Registration API
Called when owner approves unknown visitor via WP1
"""
import json
import boto3
import os
import random
import string
import time
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
rekognition = boto3.client('rekognition')
sns = boto3.client('sns')

VISITORS_TABLE = os.environ.get('VISITORS_TABLE')
PASSCODES_TABLE = os.environ.get('PASSCODES_TABLE')
PHOTOS_BUCKET = os.environ.get('PHOTOS_BUCKET')
COLLECTION_ID = os.environ.get('COLLECTION_ID')
OTP_TTL = 300


def handler(event, context):
    print(f"Event: {json.dumps(event)}")
    
    if event.get('httpMethod') == 'OPTIONS':
        return response(200, {})
    
    try:
        body = json.loads(event.get('body', '{}'))
        name = body.get('name', '').strip()
        phone = body.get('phoneNumber', '').strip()
        face_id = body.get('faceId', '').strip()
        photo_key = body.get('photoKey', '').strip()
        
        if not name:
            return response(400, {'error': 'Name required'})
        if not phone:
            return response(400, {'error': 'Phone required'})
        if not face_id:
            return response(400, {'error': 'Face ID required'})
        
        # Format phone
        if not phone.startswith('+'):
            phone = '+1' + phone.replace('-', '').replace(' ', '')
        
        # Index face in Rekognition
        rek_face_id = index_face(photo_key, face_id)
        
        # Store visitor
        store_visitor(rek_face_id, name, phone, photo_key)
        
        # Generate OTP
        otp = ''.join(random.choices(string.digits, k=6))
        store_otp(otp, rek_face_id, name)
        
        # Send SMS
        msg = f"Welcome {name}! Your Smart Door code is: {otp}. Valid for 5 minutes."
        sns.publish(PhoneNumber=phone, Message=msg)
        
        return response(200, {
            'message': 'Registered successfully',
            'visitorName': name,
            'faceId': rek_face_id
        })
        
    except Exception as e:
        print(f"Error: {e}")
        return response(500, {'error': str(e)})


def index_face(photo_key, external_id):
    try:
        # Ensure collection exists
        try:
            rekognition.create_collection(CollectionId=COLLECTION_ID)
        except rekognition.exceptions.ResourceAlreadyExistsException:
            pass
        
        if not photo_key:
            return external_id
        
        resp = rekognition.index_faces(
            CollectionId=COLLECTION_ID,
            Image={'S3Object': {'Bucket': PHOTOS_BUCKET, 'Name': photo_key}},
            ExternalImageId=external_id,
            MaxFaces=1,
            QualityFilter='AUTO'
        )
        
        if resp['FaceRecords']:
            return resp['FaceRecords'][0]['Face']['FaceId']
        return external_id
        
    except Exception as e:
        print(f"Index error: {e}")
        return external_id


def store_visitor(face_id, name, phone, photo_key):
    visitors = dynamodb.Table(VISITORS_TABLE)
    ts = datetime.utcnow().isoformat()
    
    photos = []
    if photo_key:
        photos.append({
            'objectKey': photo_key,
            'bucket': PHOTOS_BUCKET,
            'createdTimestamp': ts
        })
    
    visitors.put_item(Item={
        'faceId': face_id,
        'name': name,
        'phoneNumber': phone,
        'photos': photos,
        'createdAt': ts
    })


def store_otp(otp, face_id, name):
    passcodes = dynamodb.Table(PASSCODES_TABLE)
    passcodes.put_item(Item={
        'otp': otp,
        'faceId': face_id,
        'visitorName': name,
        'createdAt': datetime.utcnow().isoformat(),
        'ttl': int(time.time()) + OTP_TTL
    })


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
