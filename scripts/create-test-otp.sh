#!/bin/bash
# Create Test OTP Script
# Usage: ./create-test-otp.sh [otp] [visitor-name]

set -e

ENVIRONMENT=${ENVIRONMENT:-dev}
REGION=${AWS_REGION:-us-east-1}

# Add AWS CLI to PATH
if command -v python3 &> /dev/null; then
    AWS_CLI_PATH="$(python3 -m site --user-base)/bin"
    if [ -d "$AWS_CLI_PATH" ]; then
        export PATH="$PATH:$AWS_CLI_PATH"
    fi
fi

OTP=${1:-$(python3 -c "import random; print(''.join([str(random.randint(0,9)) for _ in range(6)]))")}
VISITOR_NAME=${2:-"Test Visitor"}
FACE_ID=${3:-"test-face-$(date +%s)"}

PASSCODES_TABLE="smartdoor-passcodes-${ENVIRONMENT}"

echo "=========================================="
echo "  Create Test OTP"
echo "=========================================="
echo ""

echo "Configuration:"
echo "  OTP: $OTP"
echo "  Visitor: $VISITOR_NAME"
echo "  FaceId: $FACE_ID"
echo "  Expires: 5 minutes from now"
echo ""

# Calculate TTL (5 minutes from now)
TTL=$(($(date +%s) + 300))

echo "Adding OTP to DynamoDB..."
aws dynamodb put-item \
    --table-name "$PASSCODES_TABLE" \
    --item "{
        \"otp\": {\"S\": \"$OTP\"},
        \"faceId\": {\"S\": \"$FACE_ID\"},
        \"visitorName\": {\"S\": \"$VISITOR_NAME\"},
        \"ttl\": {\"N\": \"$TTL\"},
        \"createdAt\": {\"S\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}
    }" \
    --region $REGION

echo ""
echo "=========================================="
echo "✓ Test OTP Created!"
echo "=========================================="
echo ""
echo "OTP: $OTP"
if [[ "$OSTYPE" == "darwin"* ]]; then
    EXPIRES_AT=$(date -u -r $TTL +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)
else
    EXPIRES_AT=$(date -u -d @$TTL +%Y-%m-%dT%H:%M:%SZ)
fi
echo "Expires at: $EXPIRES_AT"
echo ""
echo "Test it:"
echo "  1. Visit WP2: http://smartdoor-web-dev-437794636369.s3-website-us-east-1.amazonaws.com/wp2/index.html"
echo "  2. Enter OTP: $OTP"
echo ""
echo "Or test via API:"
echo "  curl -X POST https://1elw5cppd8.execute-api.us-east-1.amazonaws.com/dev/validate \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"otp\":\"$OTP\"}'"
echo ""

