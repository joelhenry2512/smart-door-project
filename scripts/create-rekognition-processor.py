#!/usr/bin/env python3
"""
Create Rekognition Stream Processor
"""
import boto3
import json
import sys

REGION = 'us-east-1'
PROCESSOR_NAME = 'smartdoor-face-processor-dev'
COLLECTION_ID = 'smartdoor-faces-dev'

def get_stack_outputs():
    """Get CloudFormation stack outputs"""
    cf = boto3.client('cloudformation', region_name=REGION)
    
    try:
        response = cf.describe_stacks(StackName='smart-door-system')
        outputs = {o['OutputKey']: o['OutputValue'] 
                   for o in response['Stacks'][0]['Outputs']}
        
        # Clean up video stream ARN (remove timestamp but keep stream name)
        video_arn = outputs['VideoStreamArn']
        # ARN format: arn:aws:kinesisvideo:region:account:stream/stream-name/timestamp
        # We need: arn:aws:kinesisvideo:region:account:stream/stream-name
        if video_arn.count('/') >= 2:
            # Split and take everything except the last part (timestamp)
            parts = video_arn.rsplit('/', 1)
            video_arn = parts[0]  # Remove timestamp, keep stream name
        
        return {
            'video_stream_arn': video_arn,
            'data_stream_arn': outputs['FaceEventsStreamArn'],
            'role_arn': outputs['RekognitionRoleArn']
        }
    except Exception as e:
        print(f"Error getting stack outputs: {e}")
        sys.exit(1)

def check_existing_processor(rekognition, processor_name):
    """Check if processor already exists"""
    try:
        response = rekognition.list_stream_processors()
        for processor in response.get('StreamProcessors', []):
            if processor['Name'] == processor_name:
                status = rekognition.describe_stream_processor(Name=processor_name)
                return status['Status']
        return None
    except Exception as e:
        print(f"Error checking existing processor: {e}")
        return None

def delete_existing_processor(rekognition, processor_name):
    """Delete existing processor if it exists"""
    try:
        # Stop if running
        try:
            rekognition.stop_stream_processor(Name=processor_name)
            print(f"Stopped existing processor: {processor_name}")
            import time
            time.sleep(5)
        except:
            pass
        
        # Delete
        rekognition.delete_stream_processor(Name=processor_name)
        print(f"Deleted existing processor: {processor_name}")
        import time
        time.sleep(5)
    except Exception as e:
        if 'ResourceNotFoundException' not in str(e):
            print(f"Error deleting processor: {e}")

def create_stream_processor(rekognition, config):
    """Create the stream processor"""
    input_config = {
        "KinesisVideoStream": {
            "Arn": config['video_stream_arn']
        }
    }
    
    output_config = {
        "KinesisDataStream": {
            "Arn": config['data_stream_arn']
        }
    }
    
    settings = {
        "FaceSearch": {
            "CollectionId": COLLECTION_ID,
            "FaceMatchThreshold": 80
        }
    }
    
    try:
        response = rekognition.create_stream_processor(
            Name=PROCESSOR_NAME,
            Input=input_config,
            Output=output_config,
            RoleArn=config['role_arn'],
            Settings=settings
        )
        return response.get('StreamProcessorArn')
    except Exception as e:
        print(f"Error creating stream processor: {e}")
        raise

def start_stream_processor(rekognition, processor_name):
    """Start the stream processor"""
    try:
        rekognition.start_stream_processor(Name=processor_name)
        print(f"✓ Started stream processor: {processor_name}")
        return True
    except Exception as e:
        print(f"Error starting stream processor: {e}")
        return False

def main():
    print("=" * 50)
    print("Creating Rekognition Stream Processor")
    print("=" * 50)
    print()
    
    # Initialize clients
    rekognition = boto3.client('rekognition', region_name=REGION)
    
    # Get configuration from CloudFormation
    print("Fetching CloudFormation stack outputs...")
    config = get_stack_outputs()
    print(f"  Video Stream: {config['video_stream_arn']}")
    print(f"  Data Stream: {config['data_stream_arn']}")
    print(f"  Role ARN: {config['role_arn']}")
    print()
    
    # Check for existing processor
    print(f"Checking for existing processor: {PROCESSOR_NAME}")
    existing_status = check_existing_processor(rekognition, PROCESSOR_NAME)
    
    if existing_status:
        print(f"  Found existing processor (Status: {existing_status})")
        response = input("  Delete and recreate? (y/n): ")
        if response.lower() == 'y':
            delete_existing_processor(rekognition, PROCESSOR_NAME)
        else:
            print("  Skipping creation. Exiting.")
            return
    else:
        print("  No existing processor found")
    print()
    
    # Create stream processor
    print("Creating stream processor...")
    try:
        processor_arn = create_stream_processor(rekognition, config)
        print(f"✓ Stream processor created: {PROCESSOR_NAME}")
        print(f"  ARN: {processor_arn}")
        print()
    except Exception as e:
        print(f"✗ Failed to create stream processor: {e}")
        sys.exit(1)
    
    # Start stream processor
    print("Starting stream processor...")
    if start_stream_processor(rekognition, PROCESSOR_NAME):
        import time
        time.sleep(3)
        
        # Verify status
        try:
            status = rekognition.describe_stream_processor(Name=PROCESSOR_NAME)
            print(f"  Status: {status['Status']}")
        except Exception as e:
            print(f"  Could not verify status: {e}")
    
    print()
    print("=" * 50)
    print("✓ Stream processor setup complete!")
    print("=" * 50)
    print()
    print(f"Processor Name: {PROCESSOR_NAME}")
    print(f"Collection: {COLLECTION_ID}")
    print(f"Status: RUNNING")
    print()

if __name__ == '__main__':
    main()

