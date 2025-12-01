#!/bin/bash
# Script to create GitHub repository and push code
# Usage: ./create-github-repo.sh [repo-name] [username]

set -e

REPO_NAME=${1:-smart-door-project}
GITHUB_USER=${2:-joelhenry2512}  # Update with your GitHub username if different

echo "=========================================="
echo "  Create GitHub Repository and Push"
echo "=========================================="
echo ""
echo "Repository name: $REPO_NAME"
echo "GitHub user: $GITHUB_USER"
echo ""

# Check if remote already exists
if git remote get-url origin &>/dev/null; then
    echo "Remote 'origin' already exists:"
    git remote get-url origin
    echo ""
    read -p "Do you want to use this remote? (y/n): " USE_EXISTING
    if [ "$USE_EXISTING" != "y" ]; then
        echo "Please remove the existing remote first:"
        echo "  git remote remove origin"
        exit 1
    fi
else
    echo "Adding remote repository..."
    git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"
fi

# Ensure we're on main branch
git branch -M main

echo ""
echo "=========================================="
echo "Next steps:"
echo "=========================================="
echo ""
echo "1. Create the repository on GitHub:"
echo "   Visit: https://github.com/new"
echo "   Repository name: $REPO_NAME"
echo "   Description: AWS-powered facial recognition door access system"
echo "   DO NOT initialize with README/.gitignore"
echo "   Click 'Create repository'"
echo ""
echo "2. Then run this command to push:"
echo "   git push -u origin main"
echo ""
echo "Or, if you want to push now (repo must exist first):"
read -p "Push to GitHub now? (y/n): " PUSH_NOW

if [ "$PUSH_NOW" == "y" ]; then
    echo ""
    echo "Pushing to GitHub..."
    git push -u origin main
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "✅ Successfully pushed to GitHub!"
        echo "=========================================="
        echo ""
        echo "Repository URL: https://github.com/$GITHUB_USER/$REPO_NAME"
        echo ""
    else
        echo ""
        echo "❌ Push failed. Make sure:"
        echo "   1. The repository exists on GitHub"
        echo "   2. You have push permissions"
        echo "   3. You're authenticated (may need to enter credentials)"
        echo ""
    fi
else
    echo ""
    echo "When ready, run: git push -u origin main"
fi

