#!/bin/bash
# Create Test Visitor Script
# Usage: ./create-test-visitor.sh <photo-file> <name> <phone>

set -e

ENVIRONMENT=${ENVIRONMENT:-dev}
REGION=${AWS_REGION:-us-east-1}
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Add AWS CLI to PATH
if command -v python3 &> /dev/null; then
    AWS_CLI_PATH="$(python3 -m site --user-base)/bin"
    if [ -d "$AWS_CLI_PATH" ]; then
        export PATH="$PATH:$AWS_CLI_PATH"
    fi
fi

# Get parameters
PHOTO_FILE=$1
VISITOR_NAME=${2:-"Test Visitor"}
PHONE_NUMBER=${3:-"+19472464522"}

# Get stack outputs
get_stack_output() {
    aws cloudformation describe-stacks \
        --stack-name smart-door-system \
        --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" \
        --output text \
        --region $REGION
}

echo "=========================================="
echo "  Create Test Visitor"
echo "=========================================="
echo ""

if [ -z "$PHOTO_FILE" ] || [ ! -f "$PHOTO_FILE" ]; then
    echo "Error: Photo file required"
    echo "Usage: ./create-test-visitor.sh <photo-file> [name] [phone]"
    echo ""
    echo "Example:"
    echo "  ./create-test-visitor.sh test-face.jpg \"John Doe\" \"+19472464522\""
    exit 1
fi

echo "Configuration:"
echo "  Photo: $PHOTO_FILE"
echo "  Name: $VISITOR_NAME"
echo "  Phone: $PHONE_NUMBER"
echo "  Region: $REGION"
echo ""

# Get resources
PHOTOS_BUCKET=$(get_stack_output "VisitorPhotosBucketName")
COLLECTION_ID="smartdoor-faces-${ENVIRONMENT}"
VISITORS_TABLE="smartdoor-visitors-${ENVIRONMENT}"

echo "Resources:"
echo "  S3 Bucket: $PHOTOS_BUCKET"
echo "  Collection: $COLLECTION_ID"
echo "  Table: $VISITORS_TABLE"
echo ""

# Upload photo to S3
PHOTO_KEY="test/$(basename "$PHOTO_FILE")"
echo "Step 1: Uploading photo to S3..."
aws s3 cp "$PHOTO_FILE" "s3://${PHOTOS_BUCKET}/${PHOTO_KEY}" \
    --region $REGION

echo "✓ Photo uploaded: $PHOTO_KEY"
echo ""

# Index face in Rekognition
echo "Step 2: Indexing face in Rekognition..."
EXTERNAL_ID=$(echo "$VISITOR_NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')

RESPONSE=$(aws rekognition index-faces \
    --collection-id "$COLLECTION_ID" \
    --image "{\"S3Object\":{\"Bucket\":\"${PHOTOS_BUCKET}\",\"Name\":\"${PHOTO_KEY}\"}}" \
    --external-image-id "$EXTERNAL_ID" \
    --max-faces 1 \
    --region $REGION)

FACE_ID=$(echo "$RESPONSE" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['FaceRecords'][0]['Face']['FaceId'] if data.get('FaceRecords') else '')")

if [ -z "$FACE_ID" ]; then
    echo "✗ Error: No face detected in image"
    echo "Response: $RESPONSE"
    exit 1
fi

echo "✓ Face indexed: $FACE_ID"
echo ""

# Add to DynamoDB
echo "Step 3: Adding visitor to DynamoDB..."
TTL=$(($(date +%s) + 86400))  # 24 hours from now

aws dynamodb put-item \
    --table-name "$VISITORS_TABLE" \
    --item "{
        \"faceId\": {\"S\": \"$FACE_ID\"},
        \"name\": {\"S\": \"$VISITOR_NAME\"},
        \"phoneNumber\": {\"S\": \"$PHONE_NUMBER\"},
        \"photos\": {\"L\": [{\"S\": \"$PHOTO_KEY\"}]},
        \"status\": {\"S\": \"approved\"},
        \"createdAt\": {\"S\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}
    }" \
    --region $REGION

echo "✓ Visitor added to database"
echo ""

echo "=========================================="
echo "✓ Test Visitor Created Successfully!"
echo "=========================================="
echo ""
echo "Details:"
echo "  FaceId: $FACE_ID"
echo "  Name: $VISITOR_NAME"
echo "  Phone: $PHONE_NUMBER"
echo "  Photo: s3://${PHOTOS_BUCKET}/${PHOTO_KEY}"
echo ""
echo "You can now test face recognition with this visitor!"
echo ""

