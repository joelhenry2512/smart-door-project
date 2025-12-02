# Add IAM Role Creation Permissions

## Issue

The deployment is failing because PowerUserAccess doesn't include IAM role creation permissions, which are needed to create Lambda and Rekognition service roles.

**Error:**
```
User is not authorized to perform: iam:CreateRole
```

## Solution

Add IAM permissions for role creation. You have two options:

### Option 1: Attach IAM Policy (Recommended)

Add this managed policy:
- **IAMFullAccess** (or create a custom policy with just role creation permissions)

### Option 2: Create Custom Policy (More Secure)

Create a custom policy with only the IAM permissions needed:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:GetRolePolicy",
        "iam:PassRole",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:ListRolePolicies",
        "iam:ListAttachedRolePolicies"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions"
      ],
      "Resource": "*"
    }
  ]
}
```

## Quick Steps

1. **Go to AWS Console:**
   - https://console.aws.amazon.com/iam/

2. **Attach Policy:**
   - Users → pantrypal-admin
   - Add permissions → Attach policies directly
   - Search for: **IAMFullAccess**
   - OR create a custom policy with the JSON above

3. **Retry Deployment**

---

**After adding IAM permissions, retry the deployment!**

