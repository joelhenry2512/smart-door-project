"""
LF1: Process Rekognition Video Events
Triggered by Kinesis Data Stream when faces are detected
"""
import json
import boto3
import os
import random
import string
import time
import base64
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')
sns = boto3.client('sns')
rekognition = boto3.client('rekognition')

VISITORS_TABLE = os.environ.get('VISITORS_TABLE')
PASSCODES_TABLE = os.environ.get('PASSCODES_TABLE')
PHOTOS_BUCKET = os.environ.get('PHOTOS_BUCKET')
OWNER_PHONE = os.environ.get('OWNER_PHONE')
OWNER_EMAIL = os.environ.get('OWNER_EMAIL')
COLLECTION_ID = os.environ.get('COLLECTION_ID')
WP1_URL = os.environ.get('WP1_URL')
OTP_TTL = 300  # 5 minutes


def handler(event, context):
    print(f"Event: {json.dumps(event)}")
    
    for record in event.get('Records', []):
        try:
            payload = base64.b64decode(record['kinesis']['data']).decode('utf-8')
            rek_event = json.loads(payload)
            process_event(rek_event)
        except Exception as e:
            print(f"Error: {e}")
            raise
    
    return {'statusCode': 200}


def process_event(event):
    if 'FaceSearchResponse' not in event:
        return
    
    input_info = event.get('InputInformation', {}).get('KinesisVideo', {})
    stream_arn = input_info.get('StreamArn', '')
    fragment = input_info.get('FragmentNumber', '')
    
    for face in event['FaceSearchResponse']:
        matches = face.get('MatchedFaces', [])
        
        if matches:
            # Known visitor
            face_id = matches[0]['Face']['FaceId']
            handle_known_visitor(face_id)
        else:
            # Unknown visitor
            handle_unknown_visitor(face.get('DetectedFace', {}), stream_arn, fragment)


def handle_known_visitor(face_id):
    visitors = dynamodb.Table(VISITORS_TABLE)
    resp = visitors.get_item(Key={'faceId': face_id})
    
    if 'Item' not in resp:
        return
    
    visitor = resp['Item']
    name = visitor.get('name', 'Visitor')
    phone = visitor.get('phoneNumber', '')
    
    if not phone:
        return
    
    # Generate and store OTP
    otp = ''.join(random.choices(string.digits, k=6))
    passcodes = dynamodb.Table(PASSCODES_TABLE)
    passcodes.put_item(Item={
        'otp': otp,
        'faceId': face_id,
        'visitorName': name,
        'createdAt': datetime.utcnow().isoformat(),
        'ttl': int(time.time()) + OTP_TTL
    })
    
    # Send SMS
    msg = f"Hello {name}! Your Smart Door code is: {otp}. Valid for 5 minutes."
    sns.publish(PhoneNumber=phone, Message=msg)
    print(f"OTP sent to {name}")


def handle_unknown_visitor(detected_face, stream_arn, fragment):
    temp_id = ''.join(random.choices(string.ascii_lowercase + string.digits, k=32))
    ts = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
    photo_key = f"unknown/{ts}_{temp_id}.jpg"
    
    # Save placeholder photo (in production: extract from stream)
    s3.put_object(
        Bucket=PHOTOS_BUCKET,
        Key=photo_key,
        Body=create_placeholder(),
        ContentType='image/jpeg'
    )
    
    photo_url = f"https://{PHOTOS_BUCKET}.s3.amazonaws.com/{photo_key}"
    approval_link = f"{WP1_URL}?faceId={temp_id}&photo={photo_key}"
    
    msg = f"""Unknown visitor at Smart Door!
Time: {datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC')}
Approve: {approval_link}
Photo: {photo_url}"""
    
    if OWNER_PHONE:
        sns.publish(PhoneNumber=OWNER_PHONE, Message=msg)
    
    print(f"Owner notified about unknown visitor: {temp_id}")


def create_placeholder():
    # Minimal valid JPEG
    return bytes([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
        0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
        0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
        0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
        0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
        0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
        0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
        0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
        0x09, 0x0A, 0x0B, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F,
        0x00, 0x7F, 0xFF, 0xD9
    ])
