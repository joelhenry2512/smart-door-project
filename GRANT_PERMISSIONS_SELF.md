# Grant Yourself AWS Permissions - Self-Admin Guide

Since you're the admin for the pantrypal AWS account, you can grant yourself the necessary permissions directly.

## Quick Solution: Attach Managed Policy

The easiest way is to attach the `AWSCloudFormationFullAccess` policy to your user.

### Option 1: Using AWS CLI (Recommended)

```bash
# Set your environment
export PATH="$PATH:$(python3 -m site --user-base)/bin"
export AWS_REGION=us-east-1

# Attach CloudFormation Full Access policy
aws iam attach-user-policy \
  --user-name pantrypal-admin \
  --policy-arn arn:aws:iam::aws:policy/AWSCloudFormationFullAccess \
  --region us-east-1

# Also attach PowerUserAccess for broader service access (recommended)
aws iam attach-user-policy \
  --user-name pantrypal-admin \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
  --region us-east-1

# Verify policies were attached
aws iam list-attached-user-policies --user-name pantrypal-admin --region us-east-1
```

### Option 2: Using AWS Console

1. **Go to IAM Console:**
   - https://console.aws.amazon.com/iam/

2. **Navigate to Users:**
   - Click "Users" in the left sidebar
   - Find and click "pantrypal-admin"

3. **Add Permissions:**
   - Click the "Add permissions" button
   - Select "Attach policies directly"
   - Search for and select:
     - `AWSCloudFormationFullAccess` (required for CloudFormation)
     - `PowerUserAccess` (recommended - gives access to all AWS services except IAM management)

4. **Apply:**
   - Click "Next" → "Add permissions"

## Verify Permissions

After attaching policies, verify you have the necessary access:

```bash
export PATH="$PATH:$(python3 -m site --user-base)/bin"

# Test CloudFormation access
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --region us-east-1

# Check your attached policies
aws iam list-attached-user-policies --user-name pantrypal-admin --region us-east-1

# Should see both policies listed
```

**Expected Output:**
You should see both policies in the list:
- AWSCloudFormationFullAccess
- PowerUserAccess

## Alternative: Attach Specific Policies

If you prefer to be more granular, attach these specific policies:

```bash
export PATH="$PATH:$(python3 -m site --user-base)/bin"

# CloudFormation
aws iam attach-user-policy \
  --user-name pantrypal-admin \
  --policy-arn arn:aws:iam::aws:policy/AWSCloudFormationFullAccess

# Lambda
aws iam attach-user-policy \
  --user-name pantrypal-admin \
  --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess

# DynamoDB
aws iam attach-user-policy \
  --user-name pantrypal-admin \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

# Kinesis
aws iam attach-user-policy \
  --user-name pantrypal-admin \
  --policy-arn arn:aws:iam::aws:policy/AmazonKinesisFullAccess

# API Gateway
aws iam attach-user-policy \
  --user-name pantrypal-admin \
  --policy-arn arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator

# SNS
aws iam attach-user-policy \
  --user-name pantrypal-admin \
  --policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess

# Rekognition
aws iam attach-user-policy \
  --user-name pantrypal-admin \
  --policy-arn arn:aws:iam::aws:policy/AmazonRekognitionFullAccess
```

**Note:** PowerUserAccess includes most of these, so it's simpler to just use that.

## Quick Script: Grant All Permissions at Once

Run this script to attach all necessary policies:

```bash
#!/bin/bash
export PATH="$PATH:$(python3 -m site --user-base)/bin"
export AWS_REGION=us-east-1

USER_NAME="pantrypal-admin"

echo "Attaching AWS managed policies to $USER_NAME..."

# CloudFormation (Required)
echo "Attaching AWSCloudFormationFullAccess..."
aws iam attach-user-policy \
  --user-name $USER_NAME \
  --policy-arn arn:aws:iam::aws:policy/AWSCloudFormationFullAccess

# PowerUserAccess (Recommended - includes most services)
echo "Attaching PowerUserAccess..."
aws iam attach-user-policy \
  --user-name $USER_NAME \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

echo ""
echo "Verifying attached policies..."
aws iam list-attached-user-policies --user-name $USER_NAME

echo ""
echo "✅ Permissions granted! You can now proceed with deployment."
```

## Next Steps

Once permissions are granted:

1. **Verify permissions** (commands above)
2. **Proceed with deployment:**
   ```bash
   cd /Users/joelhenry/Downloads/smart-door-project
   source .deployment-config.sh
   ./scripts/deploy-all.sh dev
   ```

## Troubleshooting

### If you get "Access Denied" when attaching policies:
- Make sure you're logged in as an admin user
- Check that your current credentials have IAM permissions
- Try using the AWS Console instead

### If policies attach but deployment still fails:
- Wait a few seconds for IAM propagation
- Try running: `aws sts get-caller-identity` to refresh credentials
- Check CloudFormation template for any resource-specific permission needs

---

**Ready to proceed?** Attach the policies above, then run the deployment!

