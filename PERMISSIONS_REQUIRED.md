# AWS Permissions Required for Deployment

## Current User Permissions

Your AWS user `pantrypal-admin` currently has:
- ✅ IAMReadOnlyAccess
- ✅ AmazonS3FullAccess

## Required Permissions for CloudFormation Deployment

To deploy the Smart Door system, you need the following additional permissions:

### CloudFormation Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:UpdateStack",
        "cloudformation:DeleteStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:DescribeStackResource",
        "cloudformation:DescribeStackResources",
        "cloudformation:GetTemplate",
        "cloudformation:ValidateTemplate"
      ],
      "Resource": "*"
    }
  ]
}
```

### IAM Permissions (for creating roles)
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
        "iam:UntagRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### Lambda Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:GetFunction",
        "lambda:DeleteFunction",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:CreateEventSourceMapping",
        "lambda:DeleteEventSourceMapping"
      ],
      "Resource": "*"
    }
  ]
}
```

### Other Required Service Permissions

**DynamoDB:**
- CreateTable, DeleteTable, DescribeTable, PutItem, GetItem, UpdateItem, DeleteItem, Query, Scan

**Kinesis:**
- CreateStream, DeleteStream, DescribeStream, ListStreams
- CreateStream (Kinesis Video)

**API Gateway:**
- CreateRestApi, DeleteRestApi, GetRestApi, PutRestApi, CreateResource, DeleteResource, PutMethod, DeleteMethod, PutIntegration, CreateDeployment, UpdateStage

**SNS:**
- CreateTopic, DeleteTopic, Subscribe, Unsubscribe, Publish

**Rekognition:**
- CreateCollection, DeleteCollection, CreateStreamProcessor, StartStreamProcessor, StopStreamProcessor

## Quick Solution

The easiest solution is to attach one of these AWS managed policies to your user:

1. **PowerUserAccess** - Provides full access to AWS services except IAM (recommended for development)
2. **AWSCloudFormationFullAccess** - Full access to CloudFormation
3. **AdministratorAccess** - Full access (not recommended for production)

Or ask your AWS administrator to grant the specific permissions listed above.

## Alternative: Manual Deployment

If you cannot get CloudFormation permissions, we can create a manual deployment script that creates each resource individually. However, this is more complex and error-prone.

---

**Contact your AWS administrator to grant these permissions, then retry the deployment.**

