# Smart Door Project - Deployment Status

## Current Status

### Prerequisites ✓
- ✅ AWS CLI installed (via pip: version 1.42.40)
- ✅ AWS credentials configured (Account: 437794636369)
- ✅ Python 3.9.6 installed
- ✅ pip3 available
- ✅ All deployment scripts are executable

### Required Configuration
Before proceeding with deployment, you need to provide:

1. **Owner Phone Number** (E.164 format)
   - Example: +12025551234
   - This will receive SMS notifications for unknown visitors

2. **Owner Email Address**
   - Example: owner@example.com
   - This will receive email notifications and SNS subscription confirmation

### Deployment Steps

To deploy the system, run:

```bash
# Option 1: Use the interactive deployment script
export PATH="$PATH:$(python3 -m site --user-base)/bin"
cd /Users/joelhenry/Downloads/smart-door-project
./scripts/deploy-all.sh dev

# Option 2: Manual step-by-step deployment
export PATH="$PATH:$(python3 -m site --user-base)/bin"
export AWS_REGION=us-east-1
export OWNER_PHONE="+1XXXXXXXXXX"  # Replace with your phone
export OWNER_EMAIL="your@email.com"  # Replace with your email

# Step 1: Deploy infrastructure
aws cloudformation deploy \
  --template-file infrastructure/cloudformation.yaml \
  --stack-name smart-door-system \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    OwnerPhoneNumber=$OWNER_PHONE \
    OwnerEmail=$OWNER_EMAIL \
    Environment=dev \
  --region us-east-1

# Step 2: Wait for stack completion
aws cloudformation wait stack-create-complete \
  --stack-name smart-door-system \
  --region us-east-1

# Step 3: Deploy Lambda functions
./scripts/deploy-lambdas.sh dev

# Step 4: Setup Rekognition
./scripts/setup-rekognition.sh dev

# Step 5: Deploy web pages
./scripts/deploy-web.sh dev
```

### Important Notes

1. **AWS Permissions**: The current AWS user (`pantrypal-admin`) may not have all required CloudFormation permissions. You may need:
   - `cloudformation:CreateStack`
   - `cloudformation:UpdateStack`
   - `cloudformation:DescribeStacks`
   - `iam:CreateRole`
   - `iam:AttachRolePolicy`
   - And various service-specific permissions

2. **SNS Subscription**: After deploying, check your email and confirm the SNS subscription to receive notifications.

3. **Rekognition Collection**: The setup script will create a Rekognition collection for face recognition.

4. **Video Streaming**: Video streaming setup is optional and can be done after the main deployment using `./scripts/start-video-stream.sh`

### Next Steps

1. Set environment variables:
   ```bash
   export OWNER_PHONE="+1XXXXXXXXXX"
   export OWNER_EMAIL="your@email.com"
   ```

2. Run the deployment script or follow the manual steps above

3. Check your email for SNS subscription confirmation

4. Test the deployment using the URLs provided at the end of deployment

### Troubleshooting

If you encounter permission errors:
- Contact your AWS administrator to grant the necessary IAM permissions
- Or use an AWS account/role with full administrative access

If AWS CLI is not found:
```bash
export PATH="$PATH:$(python3 -m site --user-base)/bin"
```

### Project Structure

- `infrastructure/cloudformation.yaml` - Main infrastructure template
- `lambda/` - Lambda function code
- `web/` - Web pages for owner approval and door access
- `scripts/` - Deployment and setup scripts
- `docs/` - Documentation

---

**Ready to deploy?** Set the OWNER_PHONE and OWNER_EMAIL environment variables and run the deployment script!

