"""
LF1 - Stream Processor Lambda Function
Processes face detection events from Kinesis Data Stream (Rekognition output)
Handles both known and unknown visitor workflows
"""

import json
import os
import boto3
import base64
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
kvs_client = boto3.client('kinesisvideo')

# Environment variables
VISITORS_TABLE = os.environ.get('VISITORS_TABLE', 'smartdoor-visitors-dev')
PASSCODES_TABLE = os.environ.get('PASSCODES_TABLE', 'smartdoor-passcodes-dev')
PHOTOS_BUCKET = os.environ.get('PHOTOS_BUCKET', 'smartdoor-visitor-photos')
SNS_TOPIC_ARN = os.environ.get('SNS_TOPIC_ARN')
OWNER_PHONE = os.environ.get('OWNER_PHONE')
COLLECTION_ID = os.environ.get('COLLECTION_ID', 'smartdoor-faces-dev')
KVS_STREAM_ARN = os.environ.get('KVS_STREAM_ARN')
API_GATEWAY_URL = os.environ.get('API_GATEWAY_URL', '')

# OTP Configuration
OTP_LENGTH = 6
OTP_TTL_SECONDS = 300  # 5 minutes

# Tables
visitors_table = dynamodb.Table(VISITORS_TABLE)
passcodes_table = dynamodb.Table(PASSCODES_TABLE)


def lambda_handler(event, context):
    """
    Main handler for Kinesis Data Stream events from Rekognition
    """
    print(f"Received event with {len(event.get('Records', []))} records")
    
    processed_faces = set()  # Avoid processing same face multiple times
    
    for record in event.get('Records', []):
        try:
            # Decode Kinesis record
            payload = base64.b64decode(record['kinesis']['data'])
            data = json.loads(payload)
            
            print(f"Processing record: {json.dumps(data, default=str)[:500]}")
            
            # Process face search response from Rekognition
            if 'FaceSearchResponse' in data:
                for face_search in data['FaceSearchResponse']:
                    detected_face = face_search.get('DetectedFace', {})
                    matched_faces = face_search.get('MatchedFaces', [])
                    
                    # Get fragment info for photo extraction
                    fragment_number = data.get('InputInformation', {}).get(
                        'KinesisVideo', {}
                    ).get('FragmentNumber')
                    
                    # Check face confidence
                    confidence = detected_face.get('Confidence', 0)
                    if confidence < 90:
                        print(f"Skipping low confidence face: {confidence}")
                        continue
                    
                    if matched_faces:
                        # KNOWN VISITOR WORKFLOW
                        best_match = matched_faces[0]  # Highest similarity
                        face_id = best_match['Face']['FaceId']
                        similarity = best_match['Similarity']
                        
                        if face_id in processed_faces:
                            continue
                        processed_faces.add(face_id)
                        
                        if similarity >= 80:  # Similarity threshold
                            print(f"Known visitor detected: {face_id} (similarity: {similarity})")
                            handle_known_visitor(face_id)
                    else:
                        # UNKNOWN VISITOR WORKFLOW
                        # Generate a temporary ID for this detection
                        temp_id = f"unknown_{int(time.time() * 1000)}"
                        
                        if temp_id in processed_faces:
                            continue
                        processed_faces.add(temp_id)
                        
                        print(f"Unknown visitor detected")
                        handle_unknown_visitor(
                            detected_face,
                            fragment_number,
                            data.get('InputInformation', {})
                        )
                        
        except Exception as e:
            print(f"Error processing record: {str(e)}")
            import traceback
            traceback.print_exc()
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'message': f'Processed {len(event.get("Records", []))} records',
            'faces_processed': len(processed_faces)
        })
    }


def handle_known_visitor(face_id: str):
    """
    Handle known visitor: Generate OTP and send SMS
    """
    try:
        # Get visitor info from DynamoDB
        response = visitors_table.get_item(Key={'faceId': face_id})
        
        if 'Item' not in response:
            print(f"Face ID {face_id} not found in visitors table")
            return
        
        visitor = response['Item']
        name = visitor.get('name', 'Visitor')
        phone_number = visitor.get('phoneNumber')
        
        if not phone_number:
            print(f"No phone number for visitor {name}")
            return
        
        # Generate and store OTP
        otp = generate_otp()
        store_otp(otp, face_id, name)
        
        # Send SMS to visitor
        message = f"Hello {name}! Your Smart Door access code is: {otp}\nThis code expires in 5 minutes."
        send_sms(phone_number, message)
        
        print(f"OTP sent to known visitor {name} at {phone_number}")
        
    except Exception as e:
        print(f"Error handling known visitor: {str(e)}")
        raise


def handle_unknown_visitor(detected_face: dict, fragment_number: str, input_info: dict):
    """
    Handle unknown visitor: Extract photo, notify owner
    """
    try:
        # Extract and upload photo from video fragment
        photo_key = extract_and_upload_photo(fragment_number, input_info)
        
        if not photo_key:
            print("Failed to extract photo from video")
            # Fall back to placeholder
            photo_key = f"unknown/placeholder_{int(time.time())}.jpg"
        
        # Generate temporary face ID for tracking
        temp_face_id = f"pending_{int(time.time() * 1000)}"
        
        # Create approval link
        approval_link = f"{API_GATEWAY_URL}/wp1?faceId={temp_face_id}&photo={photo_key}"
        
        # Store pending visitor info (optional - for tracking)
        store_pending_visitor(temp_face_id, photo_key, detected_face)
        
        # Notify owner via SMS
        message = (
            f"🚪 Smart Door Alert!\n"
            f"An unknown visitor is at your door.\n"
            f"Approve access: {approval_link}"
        )
        
        if OWNER_PHONE:
            send_sms(OWNER_PHONE, message)
        
        # Also send email via SNS topic
        if SNS_TOPIC_ARN:
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject="Smart Door: Unknown Visitor",
                Message=f"An unknown visitor is at your door.\n\nApprove access: {approval_link}\n\nPhoto: https://{PHOTOS_BUCKET}.s3.amazonaws.com/{photo_key}"
            )
        
        print(f"Owner notified about unknown visitor. Approval link: {approval_link}")
        
    except Exception as e:
        print(f"Error handling unknown visitor: {str(e)}")
        raise


def extract_and_upload_photo(fragment_number: str, input_info: dict) -> str:
    """
    Extract a frame from the video stream and upload to S3
    """
    try:
        if not fragment_number or not KVS_STREAM_ARN:
            print("Missing fragment number or stream ARN")
            return None
        
        # Get the stream name from ARN
        stream_name = KVS_STREAM_ARN.split('/')[-1]
        
        # Get data endpoint for GetMedia
        endpoint_response = kvs_client.get_data_endpoint(
            StreamARN=KVS_STREAM_ARN,
            APIName='GET_MEDIA'
        )
        endpoint = endpoint_response['DataEndpoint']
        
        # Create client with specific endpoint
        kvs_media_client = boto3.client(
            'kinesis-video-media',
            endpoint_url=endpoint
        )
        
        # Get media starting from the fragment
        media_response = kvs_media_client.get_media(
            StreamARN=KVS_STREAM_ARN,
            StartSelector={
                'StartSelectorType': 'FRAGMENT_NUMBER',
                'AfterFragmentNumber': fragment_number
            }
        )
        
        # Read stream and extract first frame
        # Note: This is simplified - in production you'd use a proper video decoder
        stream_data = media_response['Payload'].read(1024 * 1024)  # Read 1MB
        
        # For demo purposes, we'll save the raw fragment data
        # In production, use OpenCV or FFmpeg to extract actual JPEG frame
        timestamp = datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')
        photo_key = f"visitors/{timestamp}_{fragment_number[:8]}.jpg"
        
        # Upload to S3
        s3_client.put_object(
            Bucket=PHOTOS_BUCKET,
            Key=photo_key,
            Body=stream_data,
            ContentType='image/jpeg'
        )
        
        print(f"Photo uploaded to s3://{PHOTOS_BUCKET}/{photo_key}")
        return photo_key
        
    except Exception as e:
        print(f"Error extracting photo: {str(e)}")
        return None


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


def store_pending_visitor(temp_face_id: str, photo_key: str, detected_face: dict):
    """
    Store pending visitor info for approval workflow
    """
    try:
        visitors_table.put_item(
            Item={
                'faceId': temp_face_id,
                'status': 'pending',
                'photoKey': photo_key,
                'photoBucket': PHOTOS_BUCKET,
                'boundingBox': json.dumps(detected_face.get('BoundingBox', {})),
                'createdAt': datetime.now(timezone.utc).isoformat()
            }
        )
    except Exception as e:
        print(f"Error storing pending visitor: {str(e)}")


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
    # Test event
    test_event = {
        "Records": [
            {
                "kinesis": {
                    "data": base64.b64encode(json.dumps({
                        "FaceSearchResponse": [
                            {
                                "DetectedFace": {
                                    "Confidence": 99.9,
                                    "BoundingBox": {"Width": 0.2, "Height": 0.3, "Left": 0.4, "Top": 0.3}
                                },
                                "MatchedFaces": []
                            }
                        ],
                        "InputInformation": {
                            "KinesisVideo": {
                                "FragmentNumber": "12345678901234567890"
                            }
                        }
                    }).encode()).decode()
                }
            }
        ]
    }
    
    result = lambda_handler(test_event, None)
    print(f"Result: {result}")
