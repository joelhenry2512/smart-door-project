# Smart Door System - Testing Guide

## 🎯 Testing Overview

This guide walks you through testing all components of the Smart Door Authentication System.

---

## Prerequisites Check

Before testing, verify everything is deployed:

```bash
# Check stack status
aws cloudformation describe-stacks --stack-name smart-door-system --region us-east-1 --query 'Stacks[0].StackStatus'

# Check Lambda functions
aws lambda list-functions --region us-east-1 --query 'Functions[?contains(FunctionName, `smartdoor`)].FunctionName' --output table

# Check Rekognition collection
aws rekognition describe-collection --collection-id smartdoor-faces-dev --region us-east-1

# Check stream processor
aws rekognition describe-stream-processor --name smartdoor-face-processor-dev --region us-east-1 --query 'Status' --output text
```

**Expected:** All should return successful statuses.

---

## Step 1: Verify SNS Subscription

1. **Check your email:** joelhenry2512@gmail.com
2. **Look for email from AWS SNS** with subject like:
   - "AWS Notification - Subscription Confirmation"
3. **Click the confirmation link** in the email
4. **Verify subscription:**
   ```bash
   aws sns list-subscriptions-by-topic \
     --topic-arn arn:aws:sns:us-east-1:437794636369:smartdoor-notifications-dev \
     --region us-east-1
   ```

---

## Step 2: Test API Endpoints

### 2.1 Test OTP Validation (LF3)

**Create a test OTP:**
```bash
cd /Users/joelhenry/Downloads/smart-door-project
export PATH="$PATH:$(python3 -m site --user-base)/bin"
export AWS_REGION="us-east-1"

# Create test OTP (expires in 5 minutes)
TTL=$(($(date +%s) + 300))
aws dynamodb put-item \
  --table-name smartdoor-passcodes-dev \
  --item '{
    "otp": {"S": "123456"},
    "faceId": {"S": "test-face-123"},
    "visitorName": {"S": "Test Visitor"},
    "ttl": {"N": "'$TTL'"}
  }' \
  --region us-east-1

echo "Test OTP created: 123456 (expires in 5 minutes)"
```

**Test via API:**
```bash
# Test valid OTP
curl -X POST https://1elw5cppd8.execute-api.us-east-1.amazonaws.com/dev/validate \
  -H "Content-Type: application/json" \
  -d '{"otp":"123456"}'

# Test invalid OTP
curl -X POST https://1elw5cppd8.execute-api.us-east-1.amazonaws.com/dev/validate \
  -H "Content-Type: application/json" \
  -d '{"otp":"999999"}'
```

**Expected Results:**
- Valid OTP: `{"statusCode":200,"body":"{\"success\":true,\"message\":\"Access granted\"}"}`
- Invalid OTP: `{"statusCode":200,"body":"{\"success\":false,\"message\":\"Invalid or expired OTP\"}"}`

### 2.2 Test Visitor Registration (LF2)

**Test via API:**
```bash
curl -X POST https://1elw5cppd8.execute-api.us-east-1.amazonaws.com/dev/visitor \
  -H "Content-Type: application/json" \
  -d '{
    "faceId": "pending-test-123",
    "name": "John Doe",
    "phoneNumber": "+19472464522",
    "photoKey": "test/test-photo.jpg"
  }'
```

**Expected:** Response with success and OTP generation

---

## Step 3: Test Web Pages

### 3.1 Test WP2 - Virtual Door (OTP Entry)

1. **Open WP2:**
   ```
   http://smartdoor-web-dev-437794636369.s3-website-us-east-1.amazonaws.com/wp2/index.html
   ```

2. **Enter test OTP:**
   - Use the OTP you created: `123456`
   - Click "Validate OTP"

3. **Expected Result:**
   - Success message: "Access granted!"
   - Or error if OTP expired/invalid

### 3.2 Test WP1 - Owner Approval Page

1. **Open WP1:**
   ```
   http://smartdoor-web-dev-437794636369.s3-website-us-east-1.amazonaws.com/wp1/index.html?faceId=pending-test&photo=test.jpg
   ```

2. **Fill in the form:**
   - Name: Test Visitor
   - Phone: +19472464522
   - Click "Register Visitor"

3. **Expected Result:**
   - Success message
   - Visitor registered in DynamoDB
   - OTP sent via SMS/email

---

## Step 4: Add Test Face to Rekognition

### Option A: Using a Photo File

1. **Prepare a test photo:**
   - Take a clear face photo
   - Save as `test-face.jpg`

2. **Upload and index:**
   ```bash
   cd /Users/joelhenry/Downloads/smart-door-project
   export PATH="$PATH:$(python3 -m site --user-base)/bin"
   
   # Upload to S3
   aws s3 cp test-face.jpg \
     s3://smartdoor-visitor-photos-437794636369-dev/test/test-face.jpg \
     --region us-east-1
   
   # Index face in Rekognition
   RESPONSE=$(aws rekognition index-faces \
     --collection-id smartdoor-faces-dev \
     --image '{"S3Object":{"Bucket":"smartdoor-visitor-photos-437794636369-dev","Name":"test/test-face.jpg"}}' \
     --external-image-id "test-visitor" \
     --max-faces 1 \
     --region us-east-1)
   
   # Extract FaceId
   FACE_ID=$(echo $RESPONSE | python3 -c "import sys, json; print(json.load(sys.stdin)['FaceRecords'][0]['Face']['FaceId'])")
   
   echo "FaceId: $FACE_ID"
   
   # Add to DynamoDB visitors table
   aws dynamodb put-item \
     --table-name smartdoor-visitors-dev \
     --item "{
       \"faceId\": {\"S\": \"$FACE_ID\"},
       \"name\": {\"S\": \"Test Visitor\"},
       \"phoneNumber\": {\"S\": \"+19472464522\"},
       \"photos\": {\"L\": [{\"S\": \"test/test-face.jpg\"}]},
       \"status\": {\"S\": \"approved\"}
     }" \
     --region us-east-1
   
   echo "✓ Test visitor added to database"
   ```

### Option B: Using the Helper Script

Use the provided test script:
```bash
./scripts/create-test-visitor.sh test-face.jpg "Test Visitor" "+19472464522"
```

---

## Step 5: Test Lambda Functions

### 5.1 Test LF3 - OTP Validator

```bash
# Create test OTP
TTL=$(($(date +%s) + 300))
aws dynamodb put-item \
  --table-name smartdoor-passcodes-dev \
  --item '{
    "otp": {"S": "TEST123"},
    "faceId": {"S": "test-face"},
    "visitorName": {"S": "Test User"},
    "ttl": {"N": "'$TTL'"}
  }' \
  --region us-east-1

# Invoke Lambda directly
aws lambda invoke \
  --function-name smartdoor-lf3-validator-dev \
  --payload '{"body":"{\"otp\":\"TEST123\"}"}' \
  --region us-east-1 \
  /tmp/lf3-response.json

cat /tmp/lf3-response.json
```

### 5.2 Test LF2 - Visitor Registration

```bash
# Invoke Lambda directly
aws lambda invoke \
  --function-name smartdoor-lf2-registration-dev \
  --payload '{
    "body": "{
      \"faceId\": \"pending-test-456\",
      \"name\": \"Jane Doe\",
      \"phoneNumber\": \"+19472464522\",
      \"photoKey\": \"test/test-photo.jpg\"
    }"
  }' \
  --region us-east-1 \
  /tmp/lf2-response.json

cat /tmp/lf2-response.json
```

---

## Step 6: Test Complete Workflow

### 6.1 Unknown Visitor Workflow

1. **Stream video** with unknown face → Rekognition detects unknown
2. **LF1 processes** → Extracts photo, stores in S3
3. **Owner notified** → Email/SMS with approval link
4. **Owner opens WP1** → Enters visitor details
5. **LF2 registers** → Creates visitor record, sends OTP
6. **Visitor enters OTP** on WP2 → Access granted

### 6.2 Known Visitor Workflow

1. **Stream video** with known face → Rekognition matches face
2. **LF1 processes** → Retrieves visitor, generates OTP
3. **OTP sent** → SMS to visitor's phone
4. **Visitor enters OTP** on WP2 → Access granted

---

## Step 7: Monitor and Verify

### Check CloudWatch Logs

```bash
# View LF1 logs
aws logs tail /aws/lambda/smartdoor-lf1-processor-dev --follow --region us-east-1

# View LF2 logs
aws logs tail /aws/lambda/smartdoor-lf2-registration-dev --follow --region us-east-1

# View LF3 logs
aws logs tail /aws/lambda/smartdoor-lf3-validator-dev --follow --region us-east-1
```

### Check DynamoDB Tables

```bash
# List all visitors
aws dynamodb scan --table-name smartdoor-visitors-dev --region us-east-1

# List all passcodes (active ones)
aws dynamodb scan --table-name smartdoor-passcodes-dev --region us-east-1
```

### Check Kinesis Streams

```bash
# Check video stream status
aws kinesisvideo describe-stream \
  --stream-name smartdoor-video-stream-dev \
  --region us-east-1 \
  --query 'StreamInfo.Status'

# Check data stream shards
aws kinesis list-shards \
  --stream-name smartdoor-face-events-dev \
  --region us-east-1
```

---

## Testing Checklist

- [ ] SNS subscription confirmed
- [ ] API Gateway endpoints responding
- [ ] WP1 loads and displays correctly
- [ ] WP2 loads and displays correctly
- [ ] OTP validation works (valid OTP)
- [ ] OTP validation rejects invalid OTP
- [ ] Visitor registration via API works
- [ ] Test face added to Rekognition collection
- [ ] Test visitor added to DynamoDB
- [ ] Lambda functions executing correctly
- [ ] CloudWatch logs showing activity
- [ ] Stream processor running and processing

---

## Troubleshooting

### API Returns 502/503
- Check Lambda function logs in CloudWatch
- Verify Lambda has correct permissions
- Check API Gateway integration

### OTP Not Working
- Verify OTP hasn't expired (5-minute TTL)
- Check DynamoDB table has the OTP
- Verify Lambda function is invoked

### Web Pages Not Loading
- Check S3 bucket policy allows public read
- Verify bucket website hosting is enabled
- Check browser console for errors

### Stream Processor Not Working
- Verify stream processor is RUNNING
- Check Kinesis Video Stream is receiving data
- Verify IAM role has correct permissions

---

## Next Steps After Testing

1. ✅ Add real visitor faces
2. ✅ Set up video streaming
3. ✅ Monitor system performance
4. ✅ Set up CloudWatch alarms
5. ✅ Review and optimize costs

---

**Ready to test?** Start with Step 1 and work through each component!

