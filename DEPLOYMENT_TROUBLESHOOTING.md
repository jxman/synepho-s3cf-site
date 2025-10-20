# Deployment Troubleshooting Guide

This document covers common deployment issues and their solutions for the Synepho AWS hosting infrastructure.

## Table of Contents

- [GitHub Actions Deployment Failures](#github-actions-deployment-failures)
- [IAM Permission Issues](#iam-permission-issues)
- [Terraform State Issues](#terraform-state-issues)
- [CloudFront Issues](#cloudfront-issues)
- [CORS and Data Access Issues](#cors-and-data-access-issues)

---

## GitHub Actions Deployment Failures

### Issue: GitHub Actions fails with "AccessDenied" errors

**Symptoms:**
```
An error occurred (AccessDenied) when calling the CreateBucket operation:
User: arn:aws:sts::ACCOUNT:assumed-role/GithubActionsOIDC-SynephoProject-Role/GithubActionsOIDCSession
is not authorized to perform: s3:CreateBucket
```

**Root Cause:**
The GitHub Actions IAM role exists but has no policy attached, or the policy is missing required permissions.

**Solution:**

1. **Run the OIDC bootstrap script** (recommended):
   ```bash
   cd /path/to/aws-hosting-synepho
   ./scripts/bootstrap-oidc.sh
   ```

   This script will:
   - Check if the OIDC provider exists (create if needed)
   - Check if the IAM policy exists (create if needed)
   - Check if the IAM role exists (create if needed)
   - **Attach the policy to the role** (fixes the issue)

2. **Verify the fix**:
   ```bash
   # Check that policy is attached
   aws iam list-attached-role-policies --role-name GithubActionsOIDC-SynephoProject-Role

   # Expected output:
   # {
   #   "AttachedPolicies": [
   #     {
   #       "PolicyName": "GithubActions-SynephoProject-Policy",
   #       "PolicyArn": "arn:aws:iam::ACCOUNT:policy/GithubActions-SynephoProject-Policy"
   #     }
   #   ]
   # }
   ```

3. **Retry deployment**:
   ```bash
   gh workflow run "Terraform Deployment" --ref main -f environment=aws-services
   gh run watch
   ```

**Prevention:**
Always run the bootstrap script before attempting GitHub Actions deployments in a new AWS account or repository.

---

## IAM Permission Issues

### Issue: Policy not attached to role

**Check if policy exists but isn't attached:**
```bash
# List all local policies
aws iam list-policies --scope Local --query "Policies[?contains(PolicyName, 'GithubActions')].{Name:PolicyName, ARN:Arn}"

# Check role's attached policies
aws iam list-attached-role-policies --role-name GithubActionsOIDC-SynephoProject-Role

# If policy exists but isn't attached, attach it manually:
POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='GithubActions-SynephoProject-Policy'].Arn" --output text)
aws iam attach-role-policy \
  --role-name GithubActionsOIDC-SynephoProject-Role \
  --policy-arn $POLICY_ARN
```

### Issue: Insufficient permissions in policy

**If policy exists but lacks permissions:**

1. Review current policy:
   ```bash
   POLICY_ARN=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='GithubActions-SynephoProject-Policy'].Arn" --output text)
   aws iam get-policy-version \
     --policy-arn $POLICY_ARN \
     --version-id $(aws iam get-policy --policy-arn $POLICY_ARN --query 'Policy.DefaultVersionId' --output text)
   ```

2. Update policy using bootstrap script (safest):
   ```bash
   # Delete old policy version
   aws iam delete-policy --policy-arn $POLICY_ARN

   # Re-run bootstrap to create updated policy
   ./scripts/bootstrap-oidc.sh
   ```

---

## Terraform State Issues

### Issue: State file not found

**Symptoms:**
```
Error: Failed to get existing workspaces: S3 bucket does not exist.
```

**Solution:**
```bash
# Create state infrastructure
./scripts/create-prerequisites.sh

# Or create manually:
aws s3 mb s3://synepho-terraform-state --region us-east-1
aws s3api put-bucket-versioning \
  --bucket synepho-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### Issue: State locked

**Symptoms:**
```
Error: Error acquiring the state lock
```

**Solution:**
```bash
# Find the lock ID
aws dynamodb scan --table-name terraform-locks --region us-east-1

# Force unlock (use with caution - ensure no other Terraform processes running)
terraform force-unlock <LOCK_ID>
```

---

## CloudFront Issues

### Issue: 403 Forbidden errors

**Check Origin Access Control:**
```bash
# Get distribution configuration
aws cloudfront get-distribution --id EBTYLWOK3WVOK

# Verify bucket policy allows CloudFront
aws s3api get-bucket-policy --bucket www.aws-services.synepho.com --query Policy --output text | jq
```

**Verify the bucket policy includes CloudFront access:**
```json
{
  "Sid": "AllowCloudFrontServicePrincipalReadOnly",
  "Effect": "Allow",
  "Principal": {
    "Service": "cloudfront.amazonaws.com"
  },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::www.aws-services.synepho.com/*",
  "Condition": {
    "StringEquals": {
      "AWS:SourceArn": "arn:aws:cloudfront::ACCOUNT:distribution/EBTYLWOK3WVOK"
    }
  }
}
```

### Issue: Stale cache

**Clear CloudFront cache:**
```bash
aws cloudfront create-invalidation \
  --distribution-id EBTYLWOK3WVOK \
  --paths "/*"

# Monitor invalidation progress
aws cloudfront get-invalidation \
  --distribution-id EBTYLWOK3WVOK \
  --id <INVALIDATION_ID>
```

---

## CORS and Data Access Issues

### Issue: CORS errors when fetching data files

**Symptoms:**
```
Access to fetch at 'https://aws-services.synepho.com/data/complete-data.json'
from origin 'https://myapp.com' has been blocked by CORS policy
```

**Verify CORS configuration:**
```bash
aws s3api get-bucket-cors --bucket www.aws-services.synepho.com
```

**Expected output:**
```json
{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedOrigins": [
        "https://aws-services.synepho.com",
        "https://www.aws-services.synepho.com",
        "http://localhost:3000",
        "http://localhost:3002"
      ],
      "ExposeHeaders": ["ETag", "Content-Length"],
      "MaxAgeSeconds": 3600
    }
  ]
}
```

**Fix missing CORS:**
```bash
# CORS should be managed by Terraform, redeploy:
gh workflow run "Terraform Deployment" --ref main -f environment=aws-services

# Or apply manually (not recommended):
aws s3api put-bucket-cors \
  --bucket www.aws-services.synepho.com \
  --cors-configuration file://environments/aws-services/data-bucket-cors.json
```

### Issue: Lambda cannot write to S3 bucket

**Verify Lambda has write permissions:**
```bash
# Check bucket policy includes Lambda write statement
aws s3api get-bucket-policy --bucket www.aws-services.synepho.com \
  --query Policy --output text | jq '.Statement[] | select(.Sid == "AllowDataFetcherLambdaWrite")'
```

**Expected output:**
```json
{
  "Sid": "AllowDataFetcherLambdaWrite",
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::600424110307:role/sam-aws-services-fetch-DataFetcherFunctionRole-pJv38M2Owo8h"
  },
  "Action": ["s3:PutObject", "s3:PutObjectAcl"],
  "Resource": "arn:aws:s3:::www.aws-services.synepho.com/data/*"
}
```

**Test Lambda write access:**
```bash
# Manually invoke Lambda to test
aws lambda invoke \
  --function-name aws-data-fetcher \
  --cli-binary-format raw-in-base64-out \
  --payload '{"includeServiceMapping":true}' \
  response.json

# Check if files were written
aws s3 ls s3://www.aws-services.synepho.com/data/
```

---

## Verification Commands

### Check deployment status
```bash
# View recent workflow runs
gh run list --limit 5

# View specific run details
gh run view <RUN_ID>

# View failed run logs
gh run view <RUN_ID> --log-failed
```

### Verify infrastructure
```bash
# Check S3 bucket exists
aws s3 ls s3://www.aws-services.synepho.com/

# Check CloudFront distribution
aws cloudfront get-distribution --id EBTYLWOK3WVOK | jq '.Distribution.Status'

# Check DNS resolution
dig aws-services.synepho.com

# Test website access
curl -I https://aws-services.synepho.com/
```

### Check Terraform state
```bash
# Initialize with correct backend
terraform init -backend-config=environments/aws-services/backend.conf

# List resources in state
terraform state list

# Show specific resource
terraform state show module.s3_website.aws_s3_bucket_cors_configuration.www_site[0]
```

---

## Getting Help

If issues persist after following this guide:

1. **Check GitHub Actions logs**:
   ```bash
   gh run view --web
   ```

2. **Review AWS CloudTrail** for detailed error information

3. **Verify AWS credentials** have necessary permissions

4. **Check AWS service quotas** and limits

5. **Open an issue** with full error logs and context

---

## Recent Changes Log

### 2025-10-20: Lambda Data Fetcher Integration
- Added CORS configuration to S3 website module
- Updated bucket policy with Lambda write permissions
- Fixed GitHub Actions IAM policy attachment issue
- Deployed successfully via GitHub Actions

**Issue Fixed**: GitHub Actions role had no attached policy
**Solution**: Ran `./scripts/bootstrap-oidc.sh` to attach policy
**Verification**: Deployment run 18639619275 completed successfully (54s)
