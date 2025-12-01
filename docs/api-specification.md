# Smart Door API Specification

## Base URL
```
https://{api-id}.execute-api.{region}.amazonaws.com/{stage}
```

## Authentication
Currently no authentication required (for demo purposes). In production, implement API keys or OAuth.

---

## Endpoints

### POST /visitor
Register a new visitor (called from WP1 - Owner Approval Page)

**Request Body:**
```json
{
    "name": "John Doe",
    "phoneNumber": "+12025551234",
    "photoKey": "visitors/20231201_123456.jpg",
    "faceId": "pending_1701432567890"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Full name of the visitor |
| phoneNumber | string | Yes | Phone number in E.164 format |
| photoKey | string | No | S3 object key for visitor photo |
| faceId | string | No | Pending face ID from initial detection |

**Success Response (200):**
```json
{
    "message": "Visitor registered successfully",
    "faceId": "abc123-def456-ghi789",
    "name": "John Doe",
    "otpSent": true
}
```

**Error Response (400):**
```json
{
    "error": "Missing required fields: name and phoneNumber are required"
}
```

**Error Response (500):**
```json
{
    "error": "Internal server error: {details}"
}
```

---

### POST /validate
Validate an OTP code (called from WP2 - Virtual Door Page)

**Request Body:**
```json
{
    "otp": "123456"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| otp | string | Yes | 6-digit one-time passcode |

**Success Response (200) - Access Granted:**
```json
{
    "access": "granted",
    "message": "Welcome, John Doe! Door is now unlocked.",
    "visitorName": "John Doe",
    "faceId": "abc123-def456-ghi789",
    "timestamp": "2023-12-01T12:34:56.789Z"
}
```

**Error Response (400) - Invalid Format:**
```json
{
    "access": "denied",
    "message": "Invalid OTP format. Please enter a 6-digit code."
}
```

**Error Response (401) - Invalid OTP:**
```json
{
    "access": "denied",
    "message": "Invalid OTP. Please check your code and try again."
}
```

**Error Response (401) - Expired OTP:**
```json
{
    "access": "denied",
    "message": "OTP has expired. Please request a new code."
}
```

---

## Data Models

### Visitor (DynamoDB: visitors table)
```json
{
    "faceId": "abc123-def456-ghi789",
    "name": "John Doe",
    "phoneNumber": "+12025551234",
    "photos": [
        {
            "objectKey": "visitors/20231201_123456.jpg",
            "bucket": "smartdoor-visitor-photos-xxx",
            "createdTimestamp": "2023-12-01T12:34:56Z"
        }
    ],
    "createdAt": "2023-12-01T12:34:56Z",
    "status": "approved"
}
```

### Passcode (DynamoDB: passcodes table)
```json
{
    "otp": "123456",
    "faceId": "abc123-def456-ghi789",
    "visitorName": "John Doe",
    "createdAt": "2023-12-01T12:34:56Z",
    "ttl": 1701432896
}
```

---

## CORS Configuration

All endpoints support CORS with the following headers:
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: Content-Type,X-Amz-Date,Authorization,X-Api-Key
Access-Control-Allow-Methods: POST,OPTIONS
```

---

## Rate Limits
- 10,000 requests per second (API Gateway default)
- Adjust based on expected traffic

---

## Error Codes

| HTTP Code | Meaning |
|-----------|---------|
| 200 | Success |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - Invalid/expired OTP |
| 500 | Internal Server Error |

---

## Kinesis Data Stream Event Format
(Output from Rekognition Stream Processor)

```json
{
    "FaceSearchResponse": [
        {
            "DetectedFace": {
                "BoundingBox": {
                    "Width": 0.2,
                    "Height": 0.3,
                    "Left": 0.4,
                    "Top": 0.3
                },
                "Confidence": 99.9,
                "Landmarks": [...],
                "Pose": {...},
                "Quality": {...}
            },
            "MatchedFaces": [
                {
                    "Face": {
                        "FaceId": "abc123-def456-ghi789",
                        "BoundingBox": {...},
                        "Confidence": 99.9
                    },
                    "Similarity": 98.5
                }
            ]
        }
    ],
    "InputInformation": {
        "KinesisVideo": {
            "StreamArn": "arn:aws:kinesisvideo:...",
            "FragmentNumber": "12345678901234567890",
            "ServerTimestamp": 1701432567.890,
            "ProducerTimestamp": 1701432567.800
        }
    }
}
```

---

## Testing with cURL

### Register Visitor
```bash
curl -X POST \
  https://YOUR_API_URL/visitor \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Test Visitor",
    "phoneNumber": "+12025551234"
  }'
```

### Validate OTP
```bash
curl -X POST \
  https://YOUR_API_URL/validate \
  -H 'Content-Type: application/json' \
  -d '{
    "otp": "123456"
  }'
```

---

## AWS CLI Testing

### Add Test OTP to DynamoDB
```bash
# Calculate TTL (5 minutes from now)
TTL=$(( $(date +%s) + 300 ))

aws dynamodb put-item \
  --table-name smartdoor-passcodes-dev \
  --item '{
    "otp": {"S": "123456"},
    "faceId": {"S": "test-face-id"},
    "visitorName": {"S": "Test Visitor"},
    "createdAt": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"},
    "ttl": {"N": "'$TTL'"}
  }'
```

### Add Test Visitor to DynamoDB
```bash
aws dynamodb put-item \
  --table-name smartdoor-visitors-dev \
  --item '{
    "faceId": {"S": "test-face-id"},
    "name": {"S": "Test Visitor"},
    "phoneNumber": {"S": "+12025551234"},
    "photos": {"L": []},
    "createdAt": {"S": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"},
    "status": {"S": "approved"}
  }'
```
