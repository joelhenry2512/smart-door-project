#!/bin/bash
# Setup Rekognition Stream Processor
# Usage: ./setup-rekognition.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
REGION=${AWS_REGION:-us-east-1}

echo "=========================================="
echo "Smart Door - Rekognition Setup"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "=========================================="

# Configuration
COLLECTION_ID="smartdoor-faces-${ENVIRONMENT}"
PROCESSOR_NAME="smartdoor-face-processor-${ENVIRONMENT}"

# Get CloudFormation outputs
get_stack_output() {
    aws cloudformation describe-stacks \
        --stack-name smart-door-system \
        --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" \
        --output text \
        --region $REGION
}

echo ""
echo "Fetching stack outputs..."
VIDEO_STREAM_ARN=$(get_stack_output "VideoStreamArn")
DATA_STREAM_ARN=$(get_stack_output "FaceEventsStreamArn")
REKOGNITION_ROLE_ARN=$(get_stack_output "RekognitionRoleArn")

echo "Video Stream: $VIDEO_STREAM_ARN"
echo "Data Stream: $DATA_STREAM_ARN"
echo "Role ARN: $REKOGNITION_ROLE_ARN"

# Step 1: Create Rekognition Collection
echo ""
echo "Step 1: Creating Rekognition Collection..."
aws rekognition create-collection \
    --collection-id "$COLLECTION_ID" \
    --region $REGION \
    2>/dev/null || echo "Collection already exists or error occurred"

echo "✓ Collection: $COLLECTION_ID"

# Step 2: Check if stream processor exists and delete if needed
echo ""
echo "Step 2: Checking for existing stream processor..."
EXISTING=$(aws rekognition list-stream-processors \
    --region $REGION \
    --query "StreamProcessors[?Name=='$PROCESSOR_NAME'].Name" \
    --output text)

if [ -n "$EXISTING" ]; then
    echo "Stopping and deleting existing processor..."
    aws rekognition stop-stream-processor \
        --name "$PROCESSOR_NAME" \
        --region $REGION \
        2>/dev/null || true
    
    sleep 5
    
    aws rekognition delete-stream-processor \
        --name "$PROCESSOR_NAME" \
        --region $REGION \
        2>/dev/null || true
    
    sleep 5
fi

# Step 3: Create Stream Processor
echo ""
echo "Step 3: Creating Stream Processor..."

aws rekognition create-stream-processor \
    --name "$PROCESSOR_NAME" \
    --input "{\"KinesisVideoStream\":{\"Arn\":\"$VIDEO_STREAM_ARN\"}}" \
    --output "{\"KinesisDataStream\":{\"Arn\":\"$DATA_STREAM_ARN\"}}" \
    --role-arn "$REKOGNITION_ROLE_ARN" \
    --settings "{\"FaceSearch\":{\"CollectionId\":\"$COLLECTION_ID\",\"FaceMatchThreshold\":80}}" \
    --region $REGION

echo "✓ Stream Processor created: $PROCESSOR_NAME"

# Step 4: Start Stream Processor
echo ""
echo "Step 4: Starting Stream Processor..."

aws rekognition start-stream-processor \
    --name "$PROCESSOR_NAME" \
    --region $REGION

echo "✓ Stream Processor started"

# Verify status
echo ""
echo "Verifying status..."
sleep 3

STATUS=$(aws rekognition describe-stream-processor \
    --name "$PROCESSOR_NAME" \
    --region $REGION \
    --query "Status" \
    --output text)

echo ""
echo "=========================================="
echo "✓ Rekognition Setup Complete!"
echo "=========================================="
echo ""
echo "Collection ID: $COLLECTION_ID"
echo "Stream Processor: $PROCESSOR_NAME"
echo "Status: $STATUS"
echo ""
echo "To add faces to the collection:"
echo "  aws rekognition index-faces \\"
echo "    --collection-id $COLLECTION_ID \\"
echo "    --image '{\"S3Object\":{\"Bucket\":\"BUCKET\",\"Name\":\"photo.jpg\"}}' \\"
echo "    --external-image-id 'person_name'"
echo ""
echo "To stop the processor:"
echo "  aws rekognition stop-stream-processor --name $PROCESSOR_NAME"
echo ""
