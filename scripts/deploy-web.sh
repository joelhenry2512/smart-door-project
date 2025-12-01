#!/bin/bash
# Deploy Web Pages to S3 Script
# Usage: ./deploy-web.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
REGION=${AWS_REGION:-us-east-1}
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================="
echo "Smart Door - Web Deployment"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "=========================================="

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
API_URL=$(get_stack_output "ApiGatewayUrl")
PHOTOS_BUCKET=$(get_stack_output "VisitorPhotosBucketName")

echo "API URL: $API_URL"
echo "Photos Bucket: $PHOTOS_BUCKET"

# Create web hosting bucket if it doesn't exist
WEB_BUCKET="smartdoor-web-${ENVIRONMENT}-$(aws sts get-caller-identity --query Account --output text)"

echo ""
echo "Creating/updating web hosting bucket: $WEB_BUCKET"

# Create bucket (ignore error if exists)
aws s3api create-bucket \
    --bucket "$WEB_BUCKET" \
    --region "$REGION" \
    $([ "$REGION" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=$REGION") \
    2>/dev/null || true

# Enable static website hosting
aws s3 website "s3://$WEB_BUCKET" \
    --index-document index.html \
    --error-document error.html

# Set bucket policy for public read
cat > /tmp/bucket-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::$WEB_BUCKET/*"
        }
    ]
}
EOF

aws s3api put-bucket-policy \
    --bucket "$WEB_BUCKET" \
    --policy file:///tmp/bucket-policy.json

# Disable block public access
aws s3api put-public-access-block \
    --bucket "$WEB_BUCKET" \
    --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# Process and upload WP1
echo ""
echo "Processing WP1 (Owner Approval)..."
mkdir -p /tmp/wp1
cp "$PROJECT_DIR/web/wp1-owner-approval/index.html" /tmp/wp1/

# Replace placeholders
PHOTOS_BUCKET_URL="https://${PHOTOS_BUCKET}.s3.${REGION}.amazonaws.com"
sed -i "s|YOUR_API_GATEWAY_URL|$API_URL|g" /tmp/wp1/index.html
sed -i "s|YOUR_S3_BUCKET_URL|$PHOTOS_BUCKET_URL|g" /tmp/wp1/index.html

aws s3 cp /tmp/wp1/index.html "s3://$WEB_BUCKET/wp1/index.html" \
    --content-type "text/html"

# Process and upload WP2
echo "Processing WP2 (Virtual Door)..."
mkdir -p /tmp/wp2
cp "$PROJECT_DIR/web/wp2-virtual-door/index.html" /tmp/wp2/

# Replace placeholders
sed -i "s|YOUR_API_GATEWAY_URL|$API_URL|g" /tmp/wp2/index.html

aws s3 cp /tmp/wp2/index.html "s3://$WEB_BUCKET/wp2/index.html" \
    --content-type "text/html"

# Create index page
cat > /tmp/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Smart Door System</title>
    <style>
        body { font-family: system-ui, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }
        h1 { color: #1a1a2e; }
        a { display: block; padding: 15px; margin: 10px 0; background: #667eea; color: white; text-decoration: none; border-radius: 8px; text-align: center; }
        a:hover { background: #764ba2; }
    </style>
</head>
<body>
    <h1>🚪 Smart Door System</h1>
    <p>Welcome to the Smart Door Authentication System.</p>
    <a href="/wp1/index.html">WP1 - Owner Approval Page</a>
    <a href="/wp2/index.html">WP2 - Virtual Door (Enter OTP)</a>
</body>
</html>
EOF

aws s3 cp /tmp/index.html "s3://$WEB_BUCKET/index.html" \
    --content-type "text/html"

# Clean up
rm -rf /tmp/wp1 /tmp/wp2 /tmp/index.html /tmp/bucket-policy.json

# Get website URL
if [ "$REGION" == "us-east-1" ]; then
    WEB_URL="http://${WEB_BUCKET}.s3-website-${REGION}.amazonaws.com"
else
    WEB_URL="http://${WEB_BUCKET}.s3-website.${REGION}.amazonaws.com"
fi

echo ""
echo "=========================================="
echo "✓ Web pages deployed successfully!"
echo "=========================================="
echo ""
echo "Web URLs:"
echo "  Home:  $WEB_URL"
echo "  WP1:   $WEB_URL/wp1/index.html"
echo "  WP2:   $WEB_URL/wp2/index.html"
echo ""
echo "API URL: $API_URL"
echo ""
