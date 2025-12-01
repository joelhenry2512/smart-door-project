# Smart Door System - Deployment Guide

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Python 3.9+** installed
4. **Docker** (for video streaming)
5. **Phone Number** verified in SNS for SMS

## Step-by-Step Deployment

### Step 1: Clone/Setup Project
```bash
# Navigate to project directory
cd smart-door-project

# Make scripts executable
chmod +x scripts/*.sh
```

### Step 2: Deploy CloudFormation Stack

```bash
# Set your configuration
export AWS_REGION=us-east-1
export OWNER_PHONE=+1XXXXXXXXXX  # Your phone number
export OWNER_EMAIL=your@email.com

# Deploy the infrastructure
aws cloudformation deploy \
  --template-file infrastructure/cloudformation.yaml \
  --stack-name smart-door-system \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    OwnerPhoneNumber=$OWNER_PHONE \
    OwnerEmail=$OWNER_EMAIL \
    Environment=dev \
  --region $AWS_REGION

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name smart-door-system \
  --region $AWS_REGION
```

### Step 3: Verify SNS Subscription
Check your email and confirm the SNS subscription for notifications.

### Step 4: Deploy Lambda Functions

```bash
# Deploy all Lambda functions
./scripts/deploy-lambdas.sh dev
```

### Step 5: Setup Rekognition Stream Processor

```bash
# Create collection and stream processor
./scripts/setup-rekognition.sh dev
```

### Step 6: Deploy Web Pages

```bash
# Deploy WP1 and WP2 to S3
./scripts/deploy-web.sh dev
```

### Step 7: Configure Video Streaming

#### Option A: Using an IP Camera
If you have an RTSP-capable IP camera:
```bash
./scripts/start-video-stream.sh rtsp://camera-ip:554/stream
```

#### Option B: Using a Test Video File
Create a test RTSP stream from a video file:
```bash
# Install FFmpeg
sudo apt install ffmpeg

# Start RTSP server with test video
ffmpeg -re -stream_loop -1 -i test-video.mp4 \
  -c:v libx264 -f rtsp rtsp://localhost:8554/stream
```

Then in another terminal:
```bash
./scripts/start-video-stream.sh rtsp://localhost:8554/stream
```

### Step 8: Add Test Faces to Collection

```bash
# Upload a test photo to S3
aws s3 cp test-photo.jpg s3://smartdoor-visitor-photos-xxx/test/test-photo.jpg

# Index the face
aws rekognition index-faces \
  --collection-id smartdoor-faces-dev \
  --image '{"S3Object":{"Bucket":"smartdoor-visitor-photos-xxx","Name":"test/test-photo.jpg"}}' \
  --external-image-id "test-visitor" \
  --max-faces 1

# Note the FaceId returned and add to visitors table
aws dynamodb put-item \
  --table-name smartdoor-visitors-dev \
  --item '{
    "faceId": {"S": "FACE_ID_FROM_ABOVE"},
    "name": {"S": "Test Visitor"},
    "phoneNumber": {"S": "+1XXXXXXXXXX"},
    "photos": {"L": []},
    "status": {"S": "approved"}
  }'
```

### Step 9: Test the System

#### Test OTP Validation (WP2):
```bash
# Add a test OTP
TTL=$(( $(date +%s) + 300 ))
aws dynamodb put-item \
  --table-name smartdoor-passcodes-dev \
  --item '{
    "otp": {"S": "123456"},
    "faceId": {"S": "test"},
    "visitorName": {"S": "Test"},
    "ttl": {"N": "'$TTL'"}
  }'

# Now visit WP2 and enter 123456
```

#### Test Visitor Registration (WP1):
Visit the WP1 URL with test parameters:
```
https://your-bucket.s3-website-region.amazonaws.com/wp1/index.html?faceId=test&photo=test.jpg
```

---

## Verification Checklist

- [ ] CloudFormation stack created successfully
- [ ] All Lambda functions deployed
- [ ] Rekognition collection created
- [ ] Stream processor running
- [ ] Web pages accessible
- [ ] SNS email subscription confirmed
- [ ] Test OTP validation works
- [ ] Video stream connecting (check KVS console)

---

## Get Stack Outputs

```bash
# Get all outputs
aws cloudformation describe-stacks \
  --stack-name smart-door-system \
  --query 'Stacks[0].Outputs' \
  --output table

# Get specific values
API_URL=$(aws cloudformation describe-stacks \
  --stack-name smart-door-system \
  --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrl'].OutputValue" \
  --output text)

echo "API URL: $API_URL"
```

---

## Troubleshooting

### Lambda Not Triggering
- Check Kinesis Data Stream has data (CloudWatch metrics)
- Verify event source mapping is active
- Check Lambda CloudWatch logs

### OTP Not Sending
- Verify phone number format (+1XXXXXXXXXX)
- Check SNS sandbox status (may need to request production access)
- Verify Lambda has SNS permissions

### Rekognition Not Detecting Faces
- Check stream processor status: `aws rekognition describe-stream-processor --name smartdoor-face-processor-dev`
- Verify video is streaming to KVS
- Check face collection has indexed faces

### Web Page Errors
- Check browser console for CORS errors
- Verify API Gateway URL is correct
- Check S3 bucket policy allows public read

---

## Cleanup

```bash
# Stop stream processor
aws rekognition stop-stream-processor \
  --name smartdoor-face-processor-dev

# Delete stack (this will delete most resources)
aws cloudformation delete-stack \
  --stack-name smart-door-system

# Delete S3 buckets (must be empty first)
aws s3 rb s3://smartdoor-visitor-photos-xxx --force
aws s3 rb s3://smartdoor-web-dev-xxx --force

# Delete Rekognition collection
aws rekognition delete-collection \
  --collection-id smartdoor-faces-dev
```

---

## Architecture Diagram

```
┌──────────────┐
│   Camera     │
│  (RTSP)      │
└──────┬───────┘
       │
       ▼
┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│   Kinesis    │────▶│   Rekognition   │────▶│   Kinesis    │
│ Video Stream │     │ Stream Processor│     │ Data Stream  │
└──────────────┘     └─────────────────┘     └──────┬───────┘
                            │                       │
                            ▼                       ▼
                     ┌──────────────┐        ┌──────────────┐
                     │ Rekognition  │        │    Lambda    │
                     │  Collection  │        │   LF1        │
                     └──────────────┘        └──────┬───────┘
                                                    │
                    ┌───────────────────────────────┼───────────────────────────────┐
                    │                               │                               │
                    ▼                               ▼                               ▼
             ┌──────────────┐              ┌──────────────┐              ┌──────────────┐
             │   DynamoDB   │              │   DynamoDB   │              │     SNS      │
             │   visitors   │              │  passcodes   │              │  (SMS/Email) │
             └──────────────┘              └──────────────┘              └──────┬───────┘
                    │                               │                          │
                    │                               │                          │
                    ▼                               ▼                          ▼
             ┌──────────────┐              ┌──────────────┐              ┌──────────────┐
             │    Lambda    │              │    Lambda    │              │    Owner     │
             │     LF2      │              │     LF3      │              │   (Phone)    │
             └──────┬───────┘              └──────┬───────┘              └──────────────┘
                    │                               │
                    │                               │
                    ▼                               ▼
             ┌──────────────┐              ┌──────────────┐
             │  API Gateway │              │  API Gateway │
             │ POST /visitor│              │POST /validate│
             └──────┬───────┘              └──────┬───────┘
                    │                               │
                    ▼                               ▼
             ┌──────────────┐              ┌──────────────┐
             │     WP1      │              │     WP2      │
             │Owner Approval│              │ Virtual Door │
             └──────────────┘              └──────────────┘
```
