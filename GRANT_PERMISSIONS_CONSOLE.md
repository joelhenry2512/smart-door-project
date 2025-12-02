# Grant Permissions Using AWS Console

Since the `pantrypal-admin` user doesn't have permission to attach policies via CLI, use the AWS Console with an admin account.

## Step 1: Log into AWS Console

1. Go to: https://console.aws.amazon.com/
2. **Log in with your admin credentials** (root account or another admin user)

## Step 2: Navigate to IAM

1. Click "Services" at the top
2. Search for "IAM" and click it
3. Or go directly to: https://console.aws.amazon.com/iam/

## Step 3: Find the User

1. In the left sidebar, click **"Users"**
2. Find and click on **"pantrypal-admin"**

## Step 4: Add Permissions

1. Click the **"Add permissions"** button (or "Permissions" tab → "Add permissions")
2. Select **"Attach policies directly"**
3. Click **"Next"**

## Step 5: Select Policies

Search for and check the following policies:

### Required:
- ✅ **AWSCloudFormationFullAccess** (required for CloudFormation deployment)

### Recommended:
- ✅ **PowerUserAccess** (gives access to all AWS services except IAM management)
  - This is simpler than attaching individual service policies
  - Includes: Lambda, DynamoDB, Kinesis, API Gateway, SNS, Rekognition, etc.

### OR, if you prefer individual policies:
- AWSCloudFormationFullAccess
- AWSLambda_FullAccess
- AmazonDynamoDBFullAccess
- AmazonKinesisFullAccess
- AmazonAPIGatewayAdministrator
- AmazonSNSFullAccess
- AmazonRekognitionFullAccess

## Step 6: Review and Apply

1. Review the selected policies
2. Click **"Next"**
3. Click **"Add permissions"**

## Step 7: Verify

1. You should see a success message
2. The "Permissions" tab should now show the attached policies
3. Wait a few seconds for IAM changes to propagate

## Step 8: Test Permissions

Go back to your terminal and test:

```bash
cd /Users/joelhenry/Downloads/smart-door-project
export PATH="$PATH:$(python3 -m site --user-base)/bin"

# Test CloudFormation access
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --region us-east-1

# Check attached policies
aws iam list-attached-user-policies --user-name pantrypal-admin --region us-east-1
```

## Step 9: Deploy!

Once permissions are verified, proceed with deployment:

```bash
source .deployment-config.sh
./scripts/deploy-all.sh dev
```

---

## Alternative: Use Root Account

If you have access to the root account, you can also:

1. Log in with root credentials
2. Go to IAM Console
3. Follow steps above to attach policies to `pantrypal-admin`

---

## Troubleshooting

### Can't find the user?
- Make sure you're in the correct AWS account (437794636369)
- Check the region selector (shouldn't matter for IAM, but verify)

### Policies not appearing?
- Wait 10-30 seconds for IAM propagation
- Refresh the browser page
- Try logging out and back in

### Still can't attach policies?
- You may need to use a different admin user
- Or contact AWS support if this is a root account issue

---

**After granting permissions, proceed with deployment!**

