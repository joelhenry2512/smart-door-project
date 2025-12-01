# Smart Door Authentication System

AWS-powered facial recognition door access system for ECE 528 Cloud Computing.

## Architecture Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────────┐    ┌─────────────┐
│   Visitor   │───▶│    KVS1     │───▶│   Rekognition   │───▶│    KDS1     │
│  (Camera)   │    │ Video Stream│    │   StreamProc    │    │ Data Stream │
└─────────────┘    └─────────────┘    └─────────────────┘    └──────┬──────┘
                                                                    │
                   ┌────────────────────────────────────────────────┘
                   ▼
            ┌─────────────┐
            │     LF1     │──────┬──────────────────────────────────┐
            │  Processor  │      │                                  │
            └─────────────┘      │                                  │
                   │             │                                  │
        ┌──────────┴──────────┐  │                                  │
        ▼                     ▼  ▼                                  ▼
   ┌─────────┐          ┌─────────┐                           ┌─────────┐
   │   DB2   │          │   DB1   │                           │   SNS   │
   │ visitors│          │passcodes│                           │  (SMS)  │
   └─────────┘          └─────────┘                           └────┬────┘
        │                    │                                     │
        │                    │         ┌───────────────────────────┘
        │                    │         │
        │                    │    ┌────┴────┐    ┌─────────┐
        │                    │    │  Owner  │───▶│   WP1   │
        │                    │    │ (Phone) │    │Approval │
        │                    │    └─────────┘    └────┬────┘
        │                    │                        │
        │                    │                   ┌────┴────┐
        │                    │                   │   LF2   │
        │                    │                   │Register │
        │                    │                   └────┬────┘
        │                    │                        │
        └────────────────────┼────────────────────────┘
                             │
                             ▼
                        ┌─────────┐    ┌─────────┐
                        │   WP2   │───▶│   LF3   │
                        │  Door   │    │Validate │
                        └─────────┘    └─────────┘
```

## AWS Services Used

| Service | Resource Name | Purpose |
|---------|---------------|---------|
| S3 | `smartdoor-visitor-photos-{id}` | Store visitor face photos |
| DynamoDB | `smartdoor-passcodes` | Temporary OTPs (5-min TTL) |
| DynamoDB | `smartdoor-visitors` | Visitor profiles indexed by faceId |
| Kinesis Video | `smartdoor-video-stream` | Live video from camera |
| Kinesis Data | `smartdoor-face-events` | Rekognition face detection events |
| Rekognition | Collection: `smartdoor-faces` | Face matching/indexing |
| Lambda | `smartdoor-lf1-processor` | Process face detection events |
| Lambda | `smartdoor-lf2-registration` | Register new visitors |
| Lambda | `smartdoor-lf3-validator` | Validate OTP codes |
| SNS | `smartdoor-notifications` | SMS delivery |
| API Gateway | `smartdoor-api` | REST APIs for web pages |

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Python 3.9+
- Node.js 18+ (optional, for local testing)
- Docker (for video streaming)

### 1. Deploy Infrastructure

```bash
# Deploy CloudFormation stack
cd infrastructure
aws cloudformation deploy \
  --template-file cloudformation.yaml \
  --stack-name smart-door-system \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    OwnerPhoneNumber=+1XXXXXXXXXX \
    OwnerEmail=your@email.com
```

### 2. Deploy Lambda Functions

```bash
cd scripts
./deploy-lambdas.sh
```

### 3. Deploy Web Pages

```bash
cd scripts
./deploy-web.sh
```

### 4. Start Video Streaming

```bash
cd scripts
./start-video-stream.sh
```

## Project Structure

```
smart-door-project/
├── infrastructure/
│   ├── cloudformation.yaml      # Main CloudFormation template
│   └── iam-policies.json        # IAM policy definitions
├── lambda/
│   ├── lf1-stream-processor/    # Face detection event processor
│   ├── lf2-visitor-registration/# New visitor registration
│   └── lf3-otp-validator/       # OTP validation
├── web/
│   ├── wp1-owner-approval/      # Owner approval page
│   └── wp2-virtual-door/        # Virtual door OTP entry
├── scripts/
│   ├── deploy-lambdas.sh        # Lambda deployment script
│   ├── deploy-web.sh            # Web deployment script
│   └── start-video-stream.sh    # Video streaming setup
└── docs/
    └── api-specification.md     # API documentation
```

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `VISITORS_TABLE` | DynamoDB visitors table name |
| `PASSCODES_TABLE` | DynamoDB passcodes table name |
| `PHOTOS_BUCKET` | S3 bucket for visitor photos |
| `SNS_TOPIC_ARN` | SNS topic for notifications |
| `OWNER_PHONE` | Owner's phone number |
| `OWNER_EMAIL` | Owner's email address |
| `COLLECTION_ID` | Rekognition collection ID |
| `KVS_STREAM_NAME` | Kinesis Video Stream name |

## Workflows

### Known Visitor Access
1. Camera captures visitor face → KVS1
2. Rekognition detects and matches face → KDS1
3. LF1 retrieves visitor from DB2, generates OTP
4. OTP stored in DB1 (5-min TTL)
5. SMS sent to visitor's registered phone
6. Visitor enters OTP on WP2
7. LF3 validates OTP → Access granted

### Unknown Visitor Access
1. Camera captures visitor face → KVS1
2. Rekognition detects unknown face → KDS1
3. LF1 extracts photo, stores in S3
4. SMS/email sent to owner with approval link
5. Owner opens WP1, enters visitor name/phone
6. LF2 indexes face in Rekognition, creates DB2 record
7. OTP generated and stored in DB1
8. SMS sent to new visitor
9. Visitor enters OTP on WP2 → Access granted

## Testing

### Manual Testing
```bash
# Test LF3 OTP validation
aws lambda invoke \
  --function-name smartdoor-lf3-validator \
  --payload '{"otp": "123456"}' \
  response.json

# Add test face to collection
aws rekognition index-faces \
  --collection-id smartdoor-faces \
  --image '{"S3Object":{"Bucket":"bucket","Name":"photo.jpg"}}'
```

## Security Considerations

- All OTPs expire after 5 minutes (DynamoDB TTL)
- HTTPS enforced on all API endpoints
- IAM least-privilege policies
- S3 bucket not publicly accessible
- SNS messages sent only to verified numbers

## Author
Joel - ECE 528 Cloud Computing, University of Michigan-Dearborn
