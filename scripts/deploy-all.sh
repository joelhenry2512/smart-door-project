#!/bin/bash
# Master Deployment Script for Smart Door System
# This script orchestrates the complete deployment process

set -e

ENVIRONMENT=${1:-dev}
REGION=${AWS_REGION:-us-east-1}
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Add AWS CLI to PATH if installed via pip
if command -v python3 &> /dev/null; then
    AWS_CLI_PATH="$(python3 -m site --user-base)/bin"
    if [ -d "$AWS_CLI_PATH" ]; then
        export PATH="$PATH:$AWS_CLI_PATH"
    fi
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo "=========================================="
echo "  Smart Door System - Full Deployment"
echo "=========================================="
echo ""
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo ""

# Function to check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    local MISSING=0
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}✗${NC} AWS CLI is not installed"
        echo "   Install it with: pip3 install awscli"
        echo "   Or visit: https://aws.amazon.com/cli/"
        MISSING=1
    else
        echo -e "${GREEN}✓${NC} AWS CLI installed"
        AWS_VERSION=$(aws --version 2>&1)
        echo "   $AWS_VERSION"
    fi
    
    # Check AWS credentials
    if command -v aws &> /dev/null; then
        if ! aws sts get-caller-identity &> /dev/null; then
            echo -e "${RED}✗${NC} AWS credentials not configured"
            echo "   Run: aws configure"
            MISSING=1
        else
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
            echo -e "${GREEN}✓${NC} AWS credentials configured"
            echo "   Account ID: $ACCOUNT_ID"
        fi
    fi
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}✗${NC} Python 3 is not installed"
        MISSING=1
    else
        PYTHON_VERSION=$(python3 --version)
        echo -e "${GREEN}✓${NC} Python installed"
        echo "   $PYTHON_VERSION"
    fi
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        echo -e "${RED}✗${NC} pip3 is not installed"
        MISSING=1
    else
        echo -e "${GREEN}✓${NC} pip3 installed"
    fi
    
    echo ""
    
    if [ $MISSING -eq 1 ]; then
        echo -e "${RED}Prerequisites check failed. Please install missing dependencies.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}All prerequisites met!${NC}"
    echo ""
}

# Function to get user configuration
get_configuration() {
    echo "Configuration Setup"
    echo "=================="
    echo ""
    
    # Get owner phone
    if [ -z "$OWNER_PHONE" ]; then
        echo -n "Enter owner phone number (E.164 format, e.g., +12025551234): "
        read OWNER_PHONE
    fi
    
    # Validate phone format
    if [[ ! "$OWNER_PHONE" =~ ^\+[1-9][0-9]{10,14}$ ]]; then
        echo -e "${YELLOW}Warning: Phone number format may be invalid. Should be E.164 format (+country code + number)${NC}"
        echo -n "Continue anyway? (y/n): "
        read CONTINUE
        if [ "$CONTINUE" != "y" ]; then
            exit 1
        fi
    fi
    
    # Get owner email
    if [ -z "$OWNER_EMAIL" ]; then
        echo -n "Enter owner email: "
        read OWNER_EMAIL
    fi
    
    # Validate email format (basic)
    if [[ ! "$OWNER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${YELLOW}Warning: Email format may be invalid${NC}"
        echo -n "Continue anyway? (y/n): "
        read CONTINUE
        if [ "$CONTINUE" != "y" ]; then
            exit 1
        fi
    fi
    
    export OWNER_PHONE
    export OWNER_EMAIL
    
    echo ""
    echo "Configuration:"
    echo "  Phone: $OWNER_PHONE"
    echo "  Email: $OWNER_EMAIL"
    echo ""
    echo -n "Proceed with deployment? (y/n): "
    read CONFIRM
    if [ "$CONFIRM" != "y" ]; then
        echo "Deployment cancelled."
        exit 0
    fi
    echo ""
}

# Function to deploy CloudFormation
deploy_infrastructure() {
    echo "=========================================="
    echo "Step 1: Deploying Infrastructure"
    echo "=========================================="
    echo ""
    
    cd "$PROJECT_DIR/infrastructure"
    
    echo "Deploying CloudFormation stack..."
    aws cloudformation deploy \
        --template-file cloudformation.yaml \
        --stack-name smart-door-system \
        --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
        --parameter-overrides \
            OwnerPhoneNumber="$OWNER_PHONE" \
            OwnerEmail="$OWNER_EMAIL" \
            Environment="$ENVIRONMENT" \
        --region "$REGION"
    
    echo ""
    echo "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name smart-door-system \
        --region "$REGION" \
        || aws cloudformation wait stack-update-complete \
        --stack-name smart-door-system \
        --region "$REGION"
    
    echo ""
    echo -e "${GREEN}✓ Infrastructure deployed successfully${NC}"
    echo ""
    
    cd "$PROJECT_DIR"
}

# Function to deploy Lambda functions
deploy_lambdas() {
    echo "=========================================="
    echo "Step 2: Deploying Lambda Functions"
    echo "=========================================="
    echo ""
    
    cd "$PROJECT_DIR/scripts"
    ./deploy-lambdas.sh "$ENVIRONMENT"
    cd "$PROJECT_DIR"
}

# Function to setup Rekognition
setup_rekognition() {
    echo "=========================================="
    echo "Step 3: Setting up Rekognition"
    echo "=========================================="
    echo ""
    
    cd "$PROJECT_DIR/scripts"
    ./setup-rekognition.sh "$ENVIRONMENT"
    cd "$PROJECT_DIR"
}

# Function to deploy web pages
deploy_web() {
    echo "=========================================="
    echo "Step 4: Deploying Web Pages"
    echo "=========================================="
    echo ""
    
    cd "$PROJECT_DIR/scripts"
    ./deploy-web.sh "$ENVIRONMENT"
    cd "$PROJECT_DIR"
}

# Function to display final information
display_summary() {
    echo ""
    echo "=========================================="
    echo "  Deployment Summary"
    echo "=========================================="
    echo ""
    
    # Get stack outputs
    API_URL=$(aws cloudformation describe-stacks \
        --stack-name smart-door-system \
        --query "Stacks[0].Outputs[?OutputKey=='ApiGatewayUrl'].OutputValue" \
        --output text \
        --region "$REGION" 2>/dev/null || echo "N/A")
    
    PHOTOS_BUCKET=$(aws cloudformation describe-stacks \
        --stack-name smart-door-system \
        --query "Stacks[0].Outputs[?OutputKey=='VisitorPhotosBucketName'].OutputValue" \
        --output text \
        --region "$REGION" 2>/dev/null || echo "N/A")
    
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    WEB_BUCKET="smartdoor-web-${ENVIRONMENT}-${ACCOUNT_ID}"
    
    if [ "$REGION" == "us-east-1" ]; then
        WEB_URL="http://${WEB_BUCKET}.s3-website-${REGION}.amazonaws.com"
    else
        WEB_URL="http://${WEB_BUCKET}.s3-website.${REGION}.amazonaws.com"
    fi
    
    echo -e "${GREEN}✓ Deployment Complete!${NC}"
    echo ""
    echo "Important URLs:"
    echo "  API Gateway: $API_URL"
    echo "  Web Home:    $WEB_URL"
    echo "  WP1 (Owner): $WEB_URL/wp1/index.html"
    echo "  WP2 (Door):  $WEB_URL/wp2/index.html"
    echo ""
    echo "Resources:"
    echo "  Photos Bucket: $PHOTOS_BUCKET"
    echo "  Environment:   $ENVIRONMENT"
    echo "  Region:        $REGION"
    echo ""
    echo "Next Steps:"
    echo "  1. Check your email and confirm SNS subscription"
    echo "  2. Add faces to Rekognition collection (see deployment guide)"
    echo "  3. Start video streaming (optional)"
    echo ""
    echo "To start video streaming:"
    echo "  cd scripts && ./start-video-stream.sh [rtsp_url]"
    echo ""
}

# Main deployment flow
main() {
    check_prerequisites
    get_configuration
    
    deploy_infrastructure
    deploy_lambdas
    setup_rekognition
    deploy_web
    
    display_summary
}

# Run main function
main

