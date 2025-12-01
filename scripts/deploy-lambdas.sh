#!/bin/bash
# Deploy Lambda Functions Script
# Usage: ./deploy-lambdas.sh [environment]

set -e

ENVIRONMENT=${1:-dev}
REGION=${AWS_REGION:-us-east-1}
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=========================================="
echo "Smart Door - Lambda Deployment"
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "=========================================="

# Get CloudFormation outputs
get_stack_output() {
    aws cloudformation describe-stacks \
        --stack-name smart-door-system \
        --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" \
        --output text \
        --region $REGION
}

echo ""
echo "Fetching stack outputs..."
LAMBDA_ROLE_ARN=$(get_stack_output "LambdaRoleArn")
VISITORS_TABLE=$(get_stack_output "VisitorsTableName")
PASSCODES_TABLE=$(get_stack_output "PasscodesTableName")
PHOTOS_BUCKET=$(get_stack_output "VisitorPhotosBucketName")
SNS_TOPIC_ARN=$(get_stack_output "SNSTopicArn")
VIDEO_STREAM_ARN=$(get_stack_output "VideoStreamArn")
API_URL=$(get_stack_output "ApiGatewayUrl")

echo "Lambda Role: $LAMBDA_ROLE_ARN"
echo "API URL: $API_URL"

# Function to deploy a Lambda
deploy_lambda() {
    local FUNCTION_NAME=$1
    local LAMBDA_DIR=$2
    local HANDLER=${3:-index.lambda_handler}
    
    echo ""
    echo "----------------------------------------"
    echo "Deploying: $FUNCTION_NAME"
    echo "----------------------------------------"
    
    # Create temporary directory for packaging
    TEMP_DIR=$(mktemp -d)
    
    # Copy Lambda code
    cp "$LAMBDA_DIR"/*.py "$TEMP_DIR/"
    
    # Install dependencies if requirements.txt exists
    if [ -f "$LAMBDA_DIR/requirements.txt" ]; then
        pip install -r "$LAMBDA_DIR/requirements.txt" -t "$TEMP_DIR/" --quiet
    fi
    
    # Create deployment package
    cd "$TEMP_DIR"
    zip -r9 "$PROJECT_DIR/lambda/$FUNCTION_NAME.zip" . > /dev/null
    cd "$PROJECT_DIR"
    
    # Update Lambda function code
    echo "Uploading code..."
    aws lambda update-function-code \
        --function-name "smartdoor-${FUNCTION_NAME}-${ENVIRONMENT}" \
        --zip-file "fileb://lambda/$FUNCTION_NAME.zip" \
        --region $REGION \
        --output text > /dev/null
    
    # Clean up
    rm -rf "$TEMP_DIR"
    rm -f "$PROJECT_DIR/lambda/$FUNCTION_NAME.zip"
    
    echo "✓ $FUNCTION_NAME deployed successfully"
}

# Deploy LF1 - Stream Processor
deploy_lambda "lf1-processor" "$PROJECT_DIR/lambda/lf1-stream-processor"

# Deploy LF2 - Visitor Registration
deploy_lambda "lf2-registration" "$PROJECT_DIR/lambda/lf2-visitor-registration"

# Deploy LF3 - OTP Validator
deploy_lambda "lf3-validator" "$PROJECT_DIR/lambda/lf3-otp-validator"

echo ""
echo "=========================================="
echo "✓ All Lambda functions deployed!"
echo "=========================================="
echo ""
echo "Environment Variables Set:"
echo "  VISITORS_TABLE: $VISITORS_TABLE"
echo "  PASSCODES_TABLE: $PASSCODES_TABLE"
echo "  PHOTOS_BUCKET: $PHOTOS_BUCKET"
echo "  SNS_TOPIC_ARN: $SNS_TOPIC_ARN"
echo "  API_URL: $API_URL"
echo ""
