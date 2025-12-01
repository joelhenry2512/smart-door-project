#!/bin/bash
# Quick readiness check for deployment

set -e

# Add AWS CLI to PATH if installed via pip
if command -v python3 &> /dev/null; then
    AWS_CLI_PATH="$(python3 -m site --user-base)/bin"
    if [ -d "$AWS_CLI_PATH" ]; then
        export PATH="$PATH:$AWS_CLI_PATH"
    fi
fi

echo "=========================================="
echo "  Smart Door - Deployment Readiness Check"
echo "=========================================="
echo ""

ALL_READY=1

# Check AWS CLI
if command -v aws &> /dev/null; then
    echo "✓ AWS CLI: $(aws --version 2>&1)"
else
    echo "✗ AWS CLI: Not found"
    echo "  Install with: pip3 install awscli"
    ALL_READY=0
fi

# Check AWS credentials
if command -v aws &> /dev/null; then
    if aws sts get-caller-identity &> /dev/null; then
        ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
        echo "✓ AWS Credentials: Configured (Account: $ACCOUNT)"
    else
        echo "✗ AWS Credentials: Not configured"
        echo "  Run: aws configure"
        ALL_READY=0
    fi
fi

# Check Python
if command -v python3 &> /dev/null; then
    echo "✓ Python: $(python3 --version)"
else
    echo "✗ Python 3: Not found"
    ALL_READY=0
fi

# Check pip
if command -v pip3 &> /dev/null; then
    echo "✓ pip3: Installed"
else
    echo "✗ pip3: Not found"
    ALL_READY=0
fi

# Check configuration
echo ""
echo "Configuration Required:"
if [ -z "$OWNER_PHONE" ]; then
    echo "✗ OWNER_PHONE: Not set"
    echo "  Export: export OWNER_PHONE='+12025551234'"
    ALL_READY=0
else
    echo "✓ OWNER_PHONE: $OWNER_PHONE"
fi

if [ -z "$OWNER_EMAIL" ]; then
    echo "✗ OWNER_EMAIL: Not set"
    echo "  Export: export OWNER_EMAIL='your@email.com'"
    ALL_READY=0
else
    echo "✓ OWNER_EMAIL: $OWNER_EMAIL"
fi

# Check region
REGION=${AWS_REGION:-us-east-1}
echo "✓ AWS_REGION: $REGION (default: us-east-1)"

echo ""
echo "=========================================="
if [ $ALL_READY -eq 1 ]; then
    echo "✓ All checks passed! Ready to deploy."
    echo ""
    echo "To deploy, run:"
    echo "  ./scripts/deploy-all.sh dev"
    echo ""
else
    echo "✗ Not all checks passed. Please fix the issues above."
    echo ""
    exit 1
fi

