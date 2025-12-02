#!/bin/bash
# Grant AWS Permissions to pantrypal-admin user
# Run this script to attach necessary policies for Smart Door deployment

set -e

# Add AWS CLI to PATH
if command -v python3 &> /dev/null; then
    AWS_CLI_PATH="$(python3 -m site --user-base)/bin"
    if [ -d "$AWS_CLI_PATH" ]; then
        export PATH="$PATH:$AWS_CLI_PATH"
    fi
fi

USER_NAME="pantrypal-admin"
REGION="us-east-1"

echo "=========================================="
echo "  Grant AWS Permissions"
echo "=========================================="
echo ""
echo "User: $USER_NAME"
echo "Region: $REGION"
echo ""

# Check if user exists
echo "Verifying user exists..."
if ! aws iam get-user --user-name $USER_NAME &> /dev/null; then
    echo "❌ Error: User $USER_NAME not found"
    exit 1
fi
echo "✓ User found"
echo ""

# Check current policies
echo "Current attached policies:"
aws iam list-attached-user-policies --user-name $USER_NAME --output table
echo ""

# CloudFormation policy
echo "Attaching AWSCloudFormationFullAccess..."
aws iam attach-user-policy \
    --user-name $USER_NAME \
    --policy-arn arn:aws:iam::aws:policy/AWSCloudFormationFullAccess \
    2>&1 | grep -v "already attached" || echo "  (Already attached)"
echo "✓ CloudFormation access granted"
echo ""

# PowerUserAccess (recommended for development)
read -p "Attach PowerUserAccess? (recommended - gives access to all services) [y/N]: " ATTACH_POWERUSER
if [[ $ATTACH_POWERUSER =~ ^[Yy]$ ]]; then
    echo "Attaching PowerUserAccess..."
    aws iam attach-user-policy \
        --user-name $USER_NAME \
        --policy-arn arn:aws:iam::aws:policy/PowerUserAccess \
        2>&1 | grep -v "already attached" || echo "  (Already attached)"
    echo "✓ PowerUserAccess granted"
    echo ""
else
    echo "Skipping PowerUserAccess. Attaching individual service policies..."
    echo ""
    
    # Lambda
    echo "Attaching AWSLambda_FullAccess..."
    aws iam attach-user-policy \
        --user-name $USER_NAME \
        --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess \
        2>&1 | grep -v "already attached" || echo "  (Already attached)"
    
    # DynamoDB
    echo "Attaching AmazonDynamoDBFullAccess..."
    aws iam attach-user-policy \
        --user-name $USER_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess \
        2>&1 | grep -v "already attached" || echo "  (Already attached)"
    
    # Kinesis
    echo "Attaching AmazonKinesisFullAccess..."
    aws iam attach-user-policy \
        --user-name $USER_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonKinesisFullAccess \
        2>&1 | grep -v "already attached" || echo "  (Already attached)"
    
    # API Gateway
    echo "Attaching AmazonAPIGatewayAdministrator..."
    aws iam attach-user-policy \
        --user-name $USER_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator \
        2>&1 | grep -v "already attached" || echo "  (Already attached)"
    
    # SNS
    echo "Attaching AmazonSNSFullAccess..."
    aws iam attach-user-policy \
        --user-name $USER_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess \
        2>&1 | grep -v "already attached" || echo "  (Already attached)"
    
    # Rekognition
    echo "Attaching AmazonRekognitionFullAccess..."
    aws iam attach-user-policy \
        --user-name $USER_NAME \
        --policy-arn arn:aws:iam::aws:policy/AmazonRekognitionFullAccess \
        2>&1 | grep -v "already attached" || echo "  (Already attached)"
    
    echo ""
fi

# Wait a moment for IAM propagation
echo "Waiting for IAM changes to propagate..."
sleep 3

# Verify
echo ""
echo "=========================================="
echo "  Verification"
echo "=========================================="
echo ""
echo "Attached policies:"
aws iam list-attached-user-policies --user-name $USER_NAME --output table
echo ""

# Test CloudFormation access
echo "Testing CloudFormation access..."
if aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE --region $REGION &> /dev/null; then
    echo "✓ CloudFormation access verified"
else
    echo "⚠️  CloudFormation test failed (may need to wait for propagation)"
fi

echo ""
echo "=========================================="
echo "✅ Permissions granted successfully!"
echo "=========================================="
echo ""
echo "You can now proceed with deployment:"
echo "  cd /Users/joelhenry/Downloads/smart-door-project"
echo "  source .deployment-config.sh"
echo "  ./scripts/deploy-all.sh dev"
echo ""

