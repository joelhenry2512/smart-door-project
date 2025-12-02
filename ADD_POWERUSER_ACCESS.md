# Add PowerUserAccess Permission

## Issue

CloudFormation deployment is failing because we need additional service permissions:
- DynamoDB (dynamodb:DescribeTable)
- Kinesis Video (kinesisvideo:CreateStream)  
- API Gateway (apigateway:POST)
- SNS (SNS:GetTopicAttributes)

## Quick Fix

Add the **PowerUserAccess** policy which includes all these services.

### Steps:

1. **Go to AWS Console:**
   - https://console.aws.amazon.com/iam/

2. **Navigate to User:**
   - Users → pantrypal-admin

3. **Add Permission:**
   - Click "Add permissions"
   - Select "Attach policies directly"
   - Search for: **PowerUserAccess**
   - Check the box
   - Click "Next" → "Add permissions"

4. **Verify:**
   ```bash
   aws iam list-attached-user-policies --user-name pantrypal-admin
   ```
   
   Should now show:
   - AWSCloudFormationFullAccess ✓
   - PowerUserAccess ✓

5. **Retry Deployment:**
   ```bash
   cd /Users/joelhenry/Downloads/smart-door-project
   source .deployment-config.sh
   ./scripts/deploy-all.sh dev
   ```

## What PowerUserAccess Includes

- Full access to AWS services (except IAM user/group/role management)
- DynamoDB
- Kinesis & Kinesis Video
- API Gateway
- SNS
- Lambda
- S3
- Rekognition
- And all other AWS services

This is perfect for development/deployment tasks.

---

**After adding PowerUserAccess, retry the deployment!**

