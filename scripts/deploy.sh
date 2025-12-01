#!/bin/bash
# Smart Door Deployment Script
set -e

REGION="us-east-1"
OWNER_PHONE="+12345678901"  # UPDATE
OWNER_EMAIL="your@email.com"  # UPDATE

echo "=== Smart Door Deployment ==="

# Check AWS CLI
aws sts get-caller-identity > /dev/null || { echo "AWS CLI not configured"; exit 1; }
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account: $ACCOUNT_ID"

# 1. Create Rekognition Collection
echo "Creating Rekognition collection..."
aws rekognition create-collection --collection-id smartdoor-faces --region $REGION 2>/dev/null || echo "Collection exists"

# 2. Deploy CloudFormation
echo "Deploying CloudFormation..."
aws cloudformation deploy \
    --template-file infrastructure/template.yaml \
    --stack-name smartdoor-stack \
    --parameter-overrides OwnerPhone=$OWNER_PHONE OwnerEmail=$OWNER_EMAIL \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION

# 3. Get outputs
API=$(aws cloudformation describe-stacks --stack-name smartdoor-stack --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' --output text --region $REGION)
BUCKET=$(aws cloudformation describe-stacks --stack-name smartdoor-stack --query 'Stacks[0].Outputs[?OutputKey==`PhotosBucket`].OutputValue' --output text --region $REGION)
VIDEO_ARN=$(aws cloudformation describe-stacks --stack-name smartdoor-stack --query 'Stacks[0].Outputs[?OutputKey==`VideoStreamArn`].OutputValue' --output text --region $REGION)
DATA_ARN=$(aws cloudformation describe-stacks --stack-name smartdoor-stack --query 'Stacks[0].Outputs[?OutputKey==`DataStreamArn`].OutputValue' --output text --region $REGION)
REK_ROLE=$(aws cloudformation describe-stacks --stack-name smartdoor-stack --query 'Stacks[0].Outputs[?OutputKey==`RekognitionRoleArn`].OutputValue' --output text --region $REGION)

echo "API: $API"
echo "Bucket: $BUCKET"

# 4. Deploy Lambda functions
echo "Deploying Lambda functions..."
cd lambda
for f in lf1_process lf2_register lf3_validate; do
    cp ${f}.py index.py
    zip -q ${f}.zip index.py
    FUNC="smartdoor-${f//_/-}"
    aws lambda update-function-code --function-name $FUNC --zip-file fileb://${f}.zip --region $REGION > /dev/null
    rm index.py ${f}.zip
done
cd ..

# 5. Update web pages
echo "Updating web pages..."
S3_URL="https://${BUCKET}.s3.amazonaws.com"
sed -i "s|YOUR_API_ENDPOINT|${API}|g" web/wp1.html web/wp2.html
sed -i "s|YOUR_S3_BUCKET_URL|${S3_URL}|g" web/wp1.html

# 6. Create Stream Processor
echo "Creating Rekognition Stream Processor..."
aws rekognition delete-stream-processor --name smartdoor-processor --region $REGION 2>/dev/null || true
sleep 2
aws rekognition create-stream-processor \
    --name smartdoor-processor \
    --input "{\"KinesisVideoStream\":{\"Arn\":\"${VIDEO_ARN}\"}}" \
    --output "{\"KinesisDataStream\":{\"Arn\":\"${DATA_ARN}\"}}" \
    --role-arn $REK_ROLE \
    --settings "{\"FaceSearch\":{\"CollectionId\":\"smartdoor-faces\",\"FaceMatchThreshold\":80}}" \
    --region $REGION

aws rekognition start-stream-processor --name smartdoor-processor --region $REGION

# Save config
cat > config.env << EOF
API_ENDPOINT=$API
PHOTOS_BUCKET=$BUCKET
S3_URL=$S3_URL
VIDEO_STREAM_ARN=$VIDEO_ARN
DATA_STREAM_ARN=$DATA_ARN
REGION=$REGION
EOF

echo ""
echo "=== Deployment Complete ==="
echo "API: $API"
echo "Config saved to config.env"
echo ""
echo "Next: Host web/wp1.html and web/wp2.html"
