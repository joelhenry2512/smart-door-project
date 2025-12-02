# Option 1: Request AWS Permissions - Step-by-Step Guide

## Overview

This guide walks you through requesting the necessary AWS permissions from your administrator to deploy the Smart Door system.

---

## Step 1: Identify What You Need

Your AWS user `pantrypal-admin` currently has:
- ✅ IAMReadOnlyAccess
- ✅ AmazonS3FullAccess

**You need:** CloudFormation and IAM creation permissions to deploy the infrastructure.

---

## Step 2: Prepare Your Request

### Quick Request (Easiest for Administrator)

Send this message to your AWS administrator:

```
Subject: AWS Permissions Request - Smart Door Project Deployment

Hi [Admin Name],

I need additional AWS permissions to deploy my Smart Door Authentication System 
project (ECE 528 Cloud Computing).

Current User: pantrypal-admin
Account: 437794636369

Requested Action:
Please attach the following AWS managed policy to my user:
- AWSCloudFormationFullAccess

OR, if possible, attach:
- PowerUserAccess (recommended for development - gives access to all services 
  except IAM management)

This will allow me to deploy CloudFormation stacks that create:
- Lambda functions
- DynamoDB tables
- Kinesis streams
- API Gateway
- SNS topics
- Rekognition resources

The deployment will be in the us-east-1 region for development purposes.

Thank you!
[Your Name]
```

### Detailed Request (If They Need Specific Permissions)

If your administrator needs to know exact permissions, share this:

```
I need the following permissions added to user 'pantrypal-admin':

1. CloudFormation Full Access
   - Policy: AWSCloudFormationFullAccess
   OR specific actions:
   - cloudformation:CreateStack
   - cloudformation:UpdateStack
   - cloudformation:DescribeStacks
   - cloudformation:DescribeStackEvents
   - cloudformation:DescribeStackResource
   - cloudformation:DescribeStackResources
   - cloudformation:GetTemplate
   - cloudformation:ValidateTemplate

2. IAM Role Creation (for Lambda and Rekognition roles)
   - iam:CreateRole
   - iam:PassRole
   - iam:AttachRolePolicy
   - iam:PutRolePolicy

3. Additional services (if not using PowerUserAccess):
   - Lambda (CreateFunction, UpdateFunctionCode, etc.)
   - DynamoDB (CreateTable, etc.)
   - Kinesis (CreateStream, etc.)
   - API Gateway (CreateRestApi, etc.)
   - SNS (CreateTopic, etc.)
   - Rekognition (CreateCollection, etc.)

See PERMISSIONS_REQUIRED.md for complete details.
```

---

## Step 3: Provide Additional Context (Optional)

If your administrator asks for more details, share this information:

**Project Details:**
- **Purpose:** ECE 528 Cloud Computing project - Smart Door Authentication System
- **Region:** us-east-1 (development)
- **Stack Name:** smart-door-system
- **Resources Created:** ~15-20 resources (Lambda, DynamoDB, Kinesis, API Gateway, SNS, etc.)
- **Duration:** Development/testing phase
- **Cost Impact:** Minimal (development tier, pay-per-use)

**What Will Be Created:**
- 3 Lambda functions
- 2 DynamoDB tables
- 2 Kinesis streams (Video + Data)
- 1 API Gateway
- 1 SNS topic
- 2 S3 buckets
- 2 IAM roles
- 1 Rekognition collection

---

## Step 4: Verify Permissions Were Granted

Once your administrator grants permissions, verify them:

```bash
# Set your environment
export PATH="$PATH:$(python3 -m site --user-base)/bin"

# Test CloudFormation access
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --region us-east-1

# Check your attached policies
aws iam list-attached-user-policies --user-name pantrypal-admin --region us-east-1

# Test describe stacks (the action that failed before)
aws cloudformation describe-stacks --stack-name test-stack --region us-east-1 2>&1
# Should get "does not exist" (good) instead of "AccessDenied" (bad)
```

**Expected Results:**
- ✅ Should see stack list or empty list (not AccessDenied)
- ✅ Should see CloudFormation-related policies attached
- ✅ Should get "does not exist" error (not "AccessDenied")

---

## Step 5: Proceed with Deployment

Once permissions are verified, proceed with deployment:

```bash
# Navigate to project
cd /Users/joelhenry/Downloads/smart-door-project

# Load configuration
source .deployment-config.sh

# Or set manually:
export OWNER_PHONE="+19472464522"
export OWNER_EMAIL="joelhenry2512@gmail.com"
export PATH="$PATH:$(python3 -m site --user-base)/bin"
export AWS_REGION="us-east-1"

# Run deployment
./scripts/deploy-all.sh dev
```

---

## Step 6: Follow Up If Needed

If you encounter permission errors during deployment:

1. **Note the specific error message**
   - Example: "User is not authorized to perform: iam:CreateRole"

2. **Share with administrator:**
   ```
   I'm getting this permission error during deployment:
   [Error message]
   
   Could you please grant the [missing action] permission?
   ```

3. **Check PERMISSIONS_REQUIRED.md** for the specific permission needed

---

## Alternative: Using AWS Console (If You Have Access)

If you have IAM console access, you can check/request permissions yourself:

1. **Go to IAM Console:**
   - https://console.aws.amazon.com/iam/

2. **Navigate to Users:**
   - Click "Users" → Find "pantrypal-admin"

3. **Check Current Permissions:**
   - Click "Permissions" tab
   - View attached policies

4. **If You Can Attach Policies:**
   - Click "Add permissions" → "Attach policies directly"
   - Search for "AWSCloudFormationFullAccess"
   - Check the box and click "Next" → "Add permissions"

---

## Timeline Expectations

- **Simple Request:** 1-2 business days
- **Complex Request:** 3-5 business days (if security review needed)
- **Urgent Requests:** May require escalation or justification

**Tip:** Mention this is for a course project with a deadline if applicable.

---

## Troubleshooting

### If Administrator Says "Too Broad"
- Request specific permissions from `PERMISSIONS_REQUIRED.md`
- Offer to deploy to a specific development account/region
- Suggest scoping permissions to specific resource ARNs

### If Administrator Asks About Security
- Explain the project is for development/testing
- Resources use AWS best practices (IAM roles, encryption, etc.)
- Offer to limit to specific region (us-east-1)
- Can set up CloudTrail for audit logging

### If Administrator Wants More Details
- Share the CloudFormation template: `infrastructure/cloudformation.yaml`
- Explain it creates standard AWS resources (no custom code in infrastructure)
- Point to README.md for architecture overview

---

## Checklist

- [ ] Identified required permissions
- [ ] Prepared request message
- [ ] Contacted AWS administrator
- [ ] Waited for permissions to be granted
- [ ] Verified permissions with AWS CLI commands
- [ ] Proceeded with deployment
- [ ] Followed up on any additional permission errors

---

## Next Steps After Permissions Are Granted

1. ✅ Verify permissions (Step 4)
2. ✅ Run deployment (Step 5)
3. ✅ Monitor deployment progress
4. ✅ Verify SNS email subscription
5. ✅ Test the deployed system

See `QUICK_START.md` for the complete deployment guide.

---

**Need help?** Check `PERMISSIONS_REQUIRED.md` for detailed permission requirements.

