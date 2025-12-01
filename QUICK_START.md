# Quick Start Deployment Guide

## ✅ Prerequisites - ALL READY!

All prerequisites are installed and configured:
- ✅ AWS CLI (version 1.42.40)
- ✅ AWS credentials configured (Account: 437794636369)
- ✅ Python 3.9.6
- ✅ pip3
- ✅ All scripts are executable

## 🚀 Ready to Deploy!

### Step 1: Set Configuration Variables

You need to set two environment variables before deployment:

```bash
export OWNER_PHONE="+12025551234"  # Your phone number in E.164 format
export OWNER_EMAIL="your@email.com"  # Your email address
export AWS_REGION="us-east-1"  # Optional, defaults to us-east-1
```

**Important:** 
- Phone number must be in E.164 format (e.g., +12025551234)
- Email will receive SNS subscription confirmation

### Step 2: Run Deployment

#### Option A: Automated Deployment (Recommended)

```bash
cd /Users/joelhenry/Downloads/smart-door-project
export PATH="$PATH:$(python3 -m site --user-base)/bin"
./scripts/deploy-all.sh dev
```

This will:
1. ✅ Check prerequisites
2. ✅ Deploy CloudFormation infrastructure
3. ✅ Deploy all Lambda functions
4. ✅ Setup Rekognition collection and stream processor
5. ✅ Deploy web pages to S3
6. ✅ Display all URLs and next steps

#### Option B: Step-by-Step Deployment

```bash
cd /Users/joelhenry/Downloads/smart-door-project
export PATH="$PATH:$(python3 -m site --user-base)/bin"

# Deploy infrastructure
aws cloudformation deploy \
  --template-file infrastructure/cloudformation.yaml \
  --stack-name smart-door-system \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    OwnerPhoneNumber="$OWNER_PHONE" \
    OwnerEmail="$OWNER_EMAIL" \
    Environment=dev \
  --region us-east-1

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name smart-door-system \
  --region us-east-1

# Deploy Lambda functions
./scripts/deploy-lambdas.sh dev

# Setup Rekognition
./scripts/setup-rekognition.sh dev

# Deploy web pages
./scripts/deploy-web.sh dev
```

### Step 3: Verify Deployment

After deployment completes, you'll see:
- API Gateway URL
- Web page URLs (WP1 and WP2)
- S3 bucket names

**Important Next Steps:**
1. ✅ Check your email and confirm SNS subscription
2. ✅ Add test faces to Rekognition collection (see deployment guide)
3. ✅ Test the web pages

### Verification Commands

Check deployment readiness:
```bash
./scripts/check-ready.sh
```

Get stack outputs:
```bash
export PATH="$PATH:$(python3 -m site --user-base)/bin"
aws cloudformation describe-stacks \
  --stack-name smart-door-system \
  --query 'Stacks[0].Outputs' \
  --output table \
  --region us-east-1
```

## 📋 Deployment Checklist

- [x] Prerequisites installed
- [x] AWS credentials configured
- [ ] Set OWNER_PHONE environment variable
- [ ] Set OWNER_EMAIL environment variable
- [ ] Deploy CloudFormation stack
- [ ] Deploy Lambda functions
- [ ] Setup Rekognition
- [ ] Deploy web pages
- [ ] Confirm SNS subscription
- [ ] Test deployment

## 🔧 Troubleshooting

### AWS CLI Not Found
```bash
export PATH="$PATH:$(python3 -m site --user-base)/bin"
```

### Permission Errors
If you see permission errors, your AWS user may need additional IAM permissions. Contact your AWS administrator.

### Stack Already Exists
If the stack already exists, the deployment will update it. To create a fresh deployment:
```bash
aws cloudformation delete-stack --stack-name smart-door-system --region us-east-1
```

## 📚 Additional Resources

- Full deployment guide: `docs/deployment-guide.md`
- API specification: `docs/api-specification.md`
- Project README: `README.md`
- Deployment status: `DEPLOYMENT_STATUS.md`

---

**Ready?** Set your phone and email, then run `./scripts/deploy-all.sh dev`!

