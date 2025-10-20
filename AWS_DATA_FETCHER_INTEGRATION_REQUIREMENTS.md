# AWS Data Fetcher Integration Requirements

**Project**: aws-hosting-synepho (Terraform Infrastructure)
**Integration**: Allow aws-services-fetcher Lambda to distribute data files to www.aws-services.synepho.com
**Date**: 2025-10-19
**Last Updated**: 2025-10-20
**Status**: ✅ Implemented and Deployed

---

## Executive Summary

The `aws-services-fetcher` Lambda function needs to copy generated JSON data files to the `www.aws-services.synepho.com` S3 bucket for CloudFront-backed distribution. This requires infrastructure changes to the Terraform-managed website hosting infrastructure.

### Required Changes

1. **Add CORS configuration** to S3 bucket (allow web applications to fetch JSON data)
2. **Update S3 bucket policy** to allow Lambda write access
3. **Verify CloudFront configuration** supports data file distribution

---

## Background Context

### Current Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ aws-services-fetcher Lambda                                 │
│  - Fetches AWS metadata daily (2 AM UTC)                    │
│  - Saves to: s3://aws-data-fetcher-output/aws-data/        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
                 ❌ No distribution to website
```

### Target Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ aws-services-fetcher Lambda                                 │
│  1. Fetches AWS metadata daily                              │
│  2. Saves to s3://aws-data-fetcher-output/aws-data/        │
│  3. COPIES to s3://www.aws-services.synepho.com/data/      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
            ┌──────────────────────────────┐
            │ www.aws-services.synepho.com │
            │ S3 Bucket (Primary)          │
            │ └── data/                    │
            │     ├── complete-data.json   │
            │     ├── regions.json         │
            │     └── services.json        │
            └──────────────────────────────┘
                            │
                            ▼ CloudFront CDN
                            │
            ┌──────────────────────────────┐
            │ Distribution: EBTYLWOK3WVOK  │
            │ https://aws-services.        │
            │ synepho.com/data/            │
            └──────────────────────────────┘
```

### Data Files Being Distributed

| File | Size | Purpose | Update Frequency |
|------|------|---------|------------------|
| `complete-data.json` | ~239 KB | All AWS data (regions, services, mappings) | Daily at 2 AM UTC |
| `regions.json` | ~9.6 KB | AWS region information | Daily at 2 AM UTC |
| `services.json` | ~32 KB | AWS service catalog | Daily at 2 AM UTC |

### Lambda Function Details

- **Function Name**: `aws-data-fetcher`
- **Execution Role**: `arn:aws:iam::600424110307:role/sam-aws-services-fetch-DataFetcherFunctionRole-pJv38M2Owo8h`
- **Stack Name**: `sam-aws-services-fetch`
- **Deployment Method**: AWS SAM

---

## Required Infrastructure Changes

### 1. Add CORS Configuration to S3 Bucket

**Why:** Web applications need to fetch JSON data files from the S3 bucket via CloudFront. Without CORS, browsers will block cross-origin requests.

**Location:** `modules/s3-website/main.tf` (or wherever S3 bucket CORS is managed)

**Required Configuration:**

```hcl
resource "aws_s3_bucket_cors_configuration" "primary_website" {
  bucket = aws_s3_bucket.primary_website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]  # Or restrict to specific domains if preferred
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
```

**Alternative (if using manual AWS CLI):**

```bash
aws s3api put-bucket-cors --bucket www.aws-services.synepho.com --cors-configuration '{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedOrigins": ["*"],
      "ExposeHeaders": ["ETag"],
      "MaxAgeSeconds": 3000
    }
  ]
}'
```

**Validation:**

```bash
# Verify CORS is configured
aws s3api get-bucket-cors --bucket www.aws-services.synepho.com
```

---

### 2. Update S3 Bucket Policy (Allow Lambda Write Access)

**Why:** The Lambda function needs `s3:PutObject` and `s3:PutObjectAcl` permissions to copy data files to the bucket.

**Location:** `main.tf` - Update the `aws_s3_bucket_policy.primary_cf_access` resource (lines 66-107)

**Current Policy:**

```hcl
resource "aws_s3_bucket_policy" "primary_cf_access" {
  bucket = module.s3_website.primary_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3_website.primary_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.distribution_arn
          }
        }
      },
      {
        Sid    = "AllowCloudFrontServicePrincipalListBucket"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = module.s3_website.primary_bucket_arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.distribution_arn
          }
        }
      }
    ]
  })
}
```

**Updated Policy (Add Third Statement):**

```hcl
resource "aws_s3_bucket_policy" "primary_cf_access" {
  bucket = module.s3_website.primary_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3_website.primary_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.distribution_arn
          }
        }
      },
      {
        Sid    = "AllowCloudFrontServicePrincipalListBucket"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = module.s3_website.primary_bucket_arn
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.distribution_arn
          }
        }
      },
      {
        Sid    = "AllowDataFetcherLambdaWrite"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::600424110307:role/sam-aws-services-fetch-DataFetcherFunctionRole-pJv38M2Owo8h"
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${module.s3_website.primary_bucket_arn}/data/*"
      }
    ]
  })

  depends_on = [
    module.s3_website,
    module.cloudfront
  ]
}
```

**Key Changes:**
- **New Statement Sid**: `AllowDataFetcherLambdaWrite`
- **Principal**: Lambda execution role ARN
- **Actions**: `s3:PutObject`, `s3:PutObjectAcl`
- **Resource**: Only `data/*` path (not entire bucket)
- **No Condition**: Lambda can write regardless of source

**Security Considerations:**
- ✅ **Least privilege**: Only allows writes to `data/*` path
- ✅ **Specific principal**: Only the data fetcher Lambda role
- ✅ **Limited actions**: Only PUT operations, no DELETE or GET
- ✅ **No public access**: Lambda role is internal to AWS account

---

### 3. CloudFront Configuration Verification

**Why:** Ensure CloudFront properly caches and serves the data files.

**Current CloudFront Distribution:**
- **Distribution ID**: `EBTYLWOK3WVOK`
- **Domain**: `d15rw9on81rnpt.cloudfront.net`
- **Aliases**: `www.aws-services.synepho.com`, `aws-services.synepho.com`
- **Status**: Deployed

**Cache Behavior Settings (Current):**
- **MinTTL**: None (respects object headers)
- **DefaultTTL**: None (respects object headers)
- **MaxTTL**: None (respects object headers)

**Lambda Sets These Headers:**
```
Cache-Control: public, max-age=300
Content-Type: application/json
```

**Expected Behavior:**
- Files cached at edge locations for 5 minutes (300 seconds)
- After 5 minutes, CloudFront fetches fresh copy from S3
- Lambda will also trigger cache invalidation for immediate updates

**Action Required:** ✅ No changes needed - current configuration supports this use case

---

## Optional Enhancements

### CloudFront Cache Invalidation (Recommended)

The Lambda function will create CloudFront invalidation requests after updating files to ensure immediate cache refresh.

**Required IAM Permission (Lambda side - already planned):**

```json
{
  "Effect": "Allow",
  "Action": [
    "cloudfront:CreateInvalidation"
  ],
  "Resource": "arn:aws:cloudfront::600424110307:distribution/EBTYLWOK3WVOK"
}
```

**No Terraform changes needed** - this permission is added in the Lambda's SAM template.

**Cost:** First 1,000 invalidation paths per month are FREE

---

## Terraform Implementation Checklist

### Prerequisites
- [x] Review current S3 bucket policy
- [x] Verify bucket name: `www.aws-services.synepho.com`
- [x] Confirm Lambda role ARN: `arn:aws:iam::600424110307:role/sam-aws-services-fetch-DataFetcherFunctionRole-pJv38M2Owo8h`

### Code Changes
- [x] Add CORS configuration to `modules/s3-website/main.tf`
- [x] Add CORS variables to `modules/s3-website/variables.tf`
- [x] Update root `main.tf` to pass CORS variables to S3 module
- [x] Update bucket policy in `main.tf` (add Lambda write statement with conditional logic)
- [x] Add variables to root `variables.tf`
- [x] Configure `environments/aws-services/terraform.tfvars`
- [x] Run `terraform fmt` to format changes
- [x] Run `terraform validate` to check syntax

### Testing & Deployment
- [x] Run `terraform plan` and review changes
- [x] Verify only 2 resources changing:
  - `aws_s3_bucket_cors_configuration.www_site[0]` (new)
  - `aws_s3_bucket_policy.primary_cf_access` (update)
- [x] Fix GitHub Actions IAM policy attachment (ran `scripts/bootstrap-oidc.sh`)
- [x] Deploy via GitHub Actions workflow (environment: aws-services)
- [x] Monitor deployment - completed successfully in 54s
- [x] Verify no errors in deployment

### Post-Deployment Validation
- [x] Verify CORS configuration:
  ```bash
  aws s3api get-bucket-cors --bucket www.aws-services.synepho.com
  ```
  ✅ **Result**: CORS configured with specific origins (no wildcard)

- [x] Verify bucket policy includes Lambda permissions:
  ```bash
  aws s3api get-bucket-policy --bucket www.aws-services.synepho.com --query Policy --output text | jq '.Statement[] | select(.Sid == "AllowDataFetcherLambdaWrite")'
  ```
  ✅ **Result**: Lambda write permissions confirmed for `/data/*` path only

- [x] Verify CloudFront distribution accessible:
  ```bash
  curl -I https://aws-services.synepho.com/
  ```
  ✅ **Result**: HTTP 200 OK

- [ ] Test Lambda write access (will be done from aws-services-fetcher project)

---

## Rollback Plan

If issues occur after deployment:

### Option 1: Revert Terraform Changes
```bash
cd /Users/johxan/Documents/my-projects/terraform/aws-hosting-synepho
git revert <commit-hash>
# Deploy via GitHub Actions
```

### Option 2: Remove Lambda Permissions Only
Update bucket policy to remove the `AllowDataFetcherLambdaWrite` statement, keep CORS changes.

### Option 3: Manual Rollback
```bash
# Remove CORS (if needed)
aws s3api delete-bucket-cors --bucket www.aws-services.synepho.com

# Restore original bucket policy from Git history
```

---

## Security Review

### Threat Model

| Risk | Mitigation |
|------|------------|
| Lambda writes malicious content | ✅ Lambda is internal, controlled via SAM template |
| Unauthorized writes to bucket | ✅ Only specific Lambda role allowed, scoped to `data/*` |
| CORS exploitation | ✅ Only GET/HEAD methods allowed, no credentials exposed |
| Cache poisoning | ✅ CloudFront validates origin (OAC), Lambda invalidates cache |

### Compliance Considerations

- **Least Privilege**: Lambda can only write to `data/*` path
- **Audit Trail**: CloudTrail logs all S3 and CloudFront operations
- **Encryption**: S3 bucket already has encryption at rest
- **Public Access**: Blocked at bucket level, only CloudFront can read

---

## Testing Strategy

### Pre-Deployment Testing
1. Run `terraform plan` and review all changes
2. Verify only expected resources are modified
3. Check for any unexpected deletions or replacements

### Post-Deployment Testing
1. **CORS Validation**:
   ```bash
   curl -H "Origin: https://example.com" \
        -H "Access-Control-Request-Method: GET" \
        -X OPTIONS \
        https://aws-services.synepho.com/data/test.json
   ```
   Expected: `Access-Control-Allow-Origin: *`

2. **Lambda Write Test** (from aws-services-fetcher project):
   ```bash
   # Trigger Lambda manually
   aws lambda invoke \
     --function-name aws-data-fetcher \
     --cli-binary-format raw-in-base64-out \
     --payload '{"includeServiceMapping":true}' \
     response.json

   # Check if files were written
   aws s3 ls s3://www.aws-services.synepho.com/data/
   ```

3. **CloudFront Access Test**:
   ```bash
   curl -I https://aws-services.synepho.com/data/complete-data.json
   # Should return 200 OK with Cache-Control header
   ```

---

## Integration Timeline

### Phase 1: Terraform Infrastructure (This Project)
**Duration**: 30-45 minutes
**Owner**: You (working in aws-hosting-synepho project)

1. Add CORS configuration
2. Update S3 bucket policy
3. Deploy via Terraform/GitHub Actions
4. Validate changes

### Phase 2: Lambda Implementation (aws-services-fetcher project)
**Duration**: 2-3 hours
**Owner**: Claude (working in aws-services-fetcher project)

1. Add distribution code to Lambda
2. Update SAM template with permissions
3. Deploy Lambda changes
4. Test end-to-end data flow

### Phase 3: Validation (Both Projects)
**Duration**: 30 minutes
**Owner**: Joint testing

1. Trigger Lambda manually
2. Verify files in S3
3. Test CloudFront distribution
4. Verify CORS headers
5. Monitor CloudWatch logs

---

## Reference Information

### Current Infrastructure Details

**S3 Bucket:**
- Name: `www.aws-services.synepho.com`
- Region: `us-east-1` (inferred from "None" location constraint)
- Versioning: Enabled (assumed from Terraform best practices)

**CloudFront Distribution:**
- ID: `EBTYLWOK3WVOK`
- Domain: `d15rw9on81rnpt.cloudfront.net`
- Aliases: `www.aws-services.synepho.com`, `aws-services.synepho.com`
- Origin Access: CloudFront OAC (Origin Access Control)

**Lambda Function:**
- Name: `aws-data-fetcher`
- Role: `sam-aws-services-fetch-DataFetcherFunctionRole-pJv38M2Owo8h`
- Runtime: Node.js 20
- Schedule: Daily at 2 AM UTC

### File Paths in S3

After implementation, files will be at:
- `s3://www.aws-services.synepho.com/data/complete-data.json`
- `s3://www.aws-services.synepho.com/data/regions.json`
- `s3://www.aws-services.synepho.com/data/services.json`

Public URLs (via CloudFront):
- `https://aws-services.synepho.com/data/complete-data.json`
- `https://aws-services.synepho.com/data/regions.json`
- `https://aws-services.synepho.com/data/services.json`

---

## Cost Impact

### Additional Costs (Estimated)

| Resource | Current | After Change | Delta |
|----------|---------|--------------|-------|
| S3 Storage | Base | +840 KB (3 files) | ~$0.00/month |
| S3 PUT Requests | Base | +90/month (3 files × 30 days) | ~$0.00/month |
| CloudFront Requests | Base | Depends on usage | Variable |
| CloudFront Data Transfer | Base | Depends on usage | Variable |
| CloudFront Invalidations | $0 | +90/month (3 paths × 30 days) | $0.00/month (under free tier) |

**Total Additional Cost**: ~$0.00/month (negligible)

**Cost Savings**:
- Reduces direct S3 access costs (users fetch from CloudFront instead)
- CloudFront caching reduces S3 GET requests by ~95%
- Better cost protection against traffic spikes

---

## Questions & Answers

**Q: Why not use a separate S3 bucket for data files?**
A: Using the existing website bucket provides:
- Unified infrastructure (same CloudFront distribution)
- Simpler management (one bucket policy)
- Cost efficiency (no additional bucket costs)
- Consistent with the aws-services-reporter pattern

**Q: Why allow `s3:PutObjectAcl` permission?**
A: The Lambda uses `CopyObjectCommand` which may set object ACLs. This is standard for S3 copy operations and doesn't grant public access.

**Q: Can we restrict CORS to specific origins?**
A: Yes, change `"AllowedOrigins": ["*"]` to specific domains like `["https://aws-services.synepho.com", "https://www.aws-services.synepho.com"]`

**Q: What if the Lambda role ARN changes?**
A: Update the bucket policy with the new role ARN and redeploy Terraform. The Lambda deployment will fail until this is done.

**Q: How do we monitor file updates?**
A: S3 bucket logging and CloudTrail will show all PUT operations. CloudWatch Logs from Lambda show distribution success/failure.

---

## Support & Troubleshooting

### Common Issues

**Issue: Terraform plan shows bucket replacement**
**Solution**: Review changes carefully. Bucket should only be modified, not replaced. If replacement is planned, investigate why.

**Issue: CORS not working after deployment**
**Solution**: Verify CORS configuration with `aws s3api get-bucket-cors`. May need to clear browser cache.

**Issue: Lambda gets AccessDenied when writing**
**Solution**: Verify bucket policy includes Lambda role ARN and covers `data/*` path.

**Issue: CloudFront serves old data**
**Solution**: Lambda will invalidate cache. Manually invalidate if needed:
```bash
aws cloudfront create-invalidation \
  --distribution-id EBTYLWOK3WVOK \
  --paths "/data/*"
```

### Verification Commands

```bash
# Check CORS
aws s3api get-bucket-cors --bucket www.aws-services.synepho.com

# Check bucket policy
aws s3api get-bucket-policy --bucket www.aws-services.synepho.com --query Policy --output text | jq

# List files in data directory
aws s3 ls s3://www.aws-services.synepho.com/data/

# Test CloudFront access
curl -I https://aws-services.synepho.com/data/complete-data.json

# Check CloudFront cache status
curl -I https://aws-services.synepho.com/data/complete-data.json | grep -i "x-cache"
```

---

## Document Version Control

- **Version**: 1.0
- **Created**: 2025-10-19
- **Last Updated**: 2025-10-19
- **Next Review**: After implementation
- **Status**: Ready for Implementation

---

## Approval & Sign-off

- [x] Infrastructure changes reviewed
- [x] Security implications understood
- [x] Cost impact acceptable
- [x] Testing strategy approved
- [x] Rollback plan documented
- [x] Implementation completed
- [x] Deployment verified

---

## Implementation Summary (2025-10-20)

### What Was Implemented

**Infrastructure Changes:**
1. **CORS Configuration** - Added to `modules/s3-website/main.tf`
   - Conditional resource using `count` parameter
   - Supports specific origins (no wildcard for security)
   - Variables added to module for flexibility

2. **S3 Bucket Policy** - Updated in `main.tf`
   - Added conditional Lambda write permission
   - Scoped to `/data/*` path only (least privilege)
   - Uses `concat()` to conditionally add statement

3. **Variables** - Added to support configuration
   - `enable_cors` - Boolean to enable CORS (default: false)
   - `cors_allowed_origins` - List of allowed origins
   - `data_fetcher_lambda_role_arn` - Lambda IAM role ARN

4. **Environment Configuration** - `environments/aws-services/terraform.tfvars`
   - Enabled CORS with specific origins
   - Configured Lambda role ARN
   - Only affects aws-services environment

### Deployment Details

**GitHub Actions Workflow:**
- Run ID: 18639619275
- Duration: 54 seconds
- Status: ✅ Success
- Resources: 1 added, 1 changed, 0 destroyed

**Issue Encountered:**
- GitHub Actions IAM role had no attached policy
- Fixed by running `scripts/bootstrap-oidc.sh`
- Attached `GithubActions-SynephoProject-Policy` to role

**Deployed Resources:**
- Created: `module.s3_website.aws_s3_bucket_cors_configuration.www_site[0]`
- Modified: `aws_s3_bucket_policy.primary_cf_access`

### Verification Results

**1. CORS Configuration:**
```json
{
  "AllowedOrigins": [
    "https://aws-services.synepho.com",
    "https://www.aws-services.synepho.com",
    "http://localhost:3000",
    "http://localhost:3002"
  ],
  "AllowedMethods": ["GET", "HEAD"],
  "ExposeHeaders": ["ETag", "Content-Length"],
  "MaxAgeSeconds": 3600
}
```

**2. Lambda Write Permissions:**
```json
{
  "Sid": "AllowDataFetcherLambdaWrite",
  "Principal": {
    "AWS": "arn:aws:iam::600424110307:role/sam-aws-services-fetch-DataFetcherFunctionRole-pJv38M2Owo8h"
  },
  "Action": ["s3:PutObject", "s3:PutObjectAcl"],
  "Resource": "arn:aws:s3:::www.aws-services.synepho.com/data/*"
}
```

**3. CloudFront Distribution:**
- Status: Operational (HTTP 200)
- Distribution ID: EBTYLWOK3WVOK
- URL: https://aws-services.synepho.com/

### Next Steps

**For aws-services-fetcher Lambda Project:**
1. Update Lambda function to copy data files to S3
2. Test write permissions with manual invocation
3. Verify files are accessible via CloudFront
4. Implement cache invalidation for immediate updates

**Data Endpoints (Ready for Use):**
- `https://aws-services.synepho.com/data/complete-data.json`
- `https://aws-services.synepho.com/data/regions.json`
- `https://aws-services.synepho.com/data/services.json`

### Files Modified

**Commit:** `beb343a` - feat: add Lambda data fetcher integration for aws-services environment

**Changed Files:**
- `modules/s3-website/main.tf` - Added CORS configuration
- `modules/s3-website/variables.tf` - Added CORS variables
- `main.tf` - Updated bucket policy and module call
- `variables.tf` - Added root-level variables
- `environments/aws-services/terraform.tfvars` - Environment configuration

---

**End of Requirements Document**
