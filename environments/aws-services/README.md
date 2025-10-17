# AWS Services Dashboard Environment

This environment deploys the AWS Infrastructure Dashboard at `https://aws-services.synepho.com`.

## Overview

The AWS Services Dashboard is a React-based web application that displays real-time AWS infrastructure data across regions and services, consuming data from the `aws-data-fetcher-output` S3 bucket.

## Resources Created

- **S3 Buckets:**
  - `www.aws-services.synepho.com` (primary, us-east-1)
  - `www.aws-services.synepho.com-secondary` (failover, us-west-1)
  - `aws-services.synepho.com-site-logs` (logs)

- **CloudFront Distribution:** Dedicated CDN for aws-services.synepho.com

- **ACM Certificate:** SSL/TLS certificate for aws-services.synepho.com

- **Route53 A Record:** Points aws-services.synepho.com to CloudFront distribution

- **CloudWatch:** Dashboard and alarms for monitoring

## Prerequisites

### 1. Configure Data Bucket CORS Policy

The React app needs to fetch data from `aws-data-fetcher-output` bucket. Apply the CORS policy:

```bash
# Apply CORS configuration to data bucket
aws s3api put-bucket-cors \
  --bucket aws-data-fetcher-output \
  --cors-configuration file://data-bucket-cors.json
```

### 2. Verify Data Bucket Access

Ensure the data bucket has appropriate access policy. The React app will fetch:
- `complete-data.json`
- `regions.json` (optional)
- `services.json` (optional)

**Option A: Public Read Access (Recommended for MVP)**
```bash
# Add bucket policy for public read on data files
aws s3api put-bucket-policy \
  --bucket aws-data-fetcher-output \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::aws-data-fetcher-output/complete-data.json"
    }]
  }'
```

**Option B: CloudFront Origin Access Control (More Secure)**
Add CloudFront OAC permissions (requires infrastructure modification).

## Deployment

### Local Deployment

```bash
# Navigate to Terraform directory
cd /Users/johxan/Documents/my-projects/terraform/aws-hosting-synepho

# Initialize Terraform with aws-services backend
terraform init -backend-config=environments/aws-services/backend.conf

# Plan deployment
terraform plan -var-file=environments/aws-services/terraform.tfvars -out=tfplan

# Apply infrastructure
terraform apply tfplan

# Get outputs
terraform output
```

### GitHub Actions Deployment

```bash
# Trigger workflow manually
gh workflow run terraform.yml -f environment=aws-services

# Monitor deployment
gh run list --limit 5
gh run view --web
```

## Post-Deployment Steps

### 1. Note CloudFront Distribution ID

```bash
# Get distribution ID from outputs
terraform output cloudfront_distribution_id
```

Save this for React app deployment configuration.

### 2. Verify DNS Resolution

```bash
# Wait 2-5 minutes for DNS propagation
dig aws-services.synepho.com

# Test HTTPS access
curl -I https://aws-services.synepho.com
```

### 3. Upload Initial HTML

```bash
# Create temporary index.html
cat > /tmp/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AWS Infrastructure Dashboard</title>
</head>
<body>
  <h1>AWS Infrastructure Dashboard</h1>
  <p>Coming Soon...</p>
</body>
</html>
EOF

# Upload to S3
aws s3 cp /tmp/index.html s3://www.aws-services.synepho.com/index.html

# Invalidate CloudFront cache
DIST_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

### 4. Verify Data Access

Test that the React app can fetch data from the data bucket:

```bash
# Test CORS headers
curl -I \
  -H "Origin: https://aws-services.synepho.com" \
  -H "Access-Control-Request-Method: GET" \
  https://aws-data-fetcher-output.s3.amazonaws.com/complete-data.json

# Expected response should include:
# access-control-allow-origin: https://aws-services.synepho.com
# access-control-allow-methods: GET, HEAD
```

## React App Deployment

Once infrastructure is ready, deploy the React application:

```bash
# Navigate to React app directory
cd /Users/johxan/Documents/my-projects/nodejs/aws-services-site

# Build React app
npm run build

# Deploy to S3
aws s3 sync build/ s3://www.aws-services.synepho.com --delete

# Invalidate CloudFront cache
DIST_ID=$(cd /Users/johxan/Documents/my-projects/terraform/aws-hosting-synepho && terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

## Monitoring

### CloudWatch Dashboard

```bash
# Get dashboard URL
echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=aws-services.synepho.com-dashboard"
```

### View Logs

```bash
# CloudFront access logs
aws s3 ls s3://aws-services.synepho.com-site-logs/ --recursive

# Download recent logs
aws s3 sync s3://aws-services.synepho.com-site-logs/ ./logs/ --exclude "*" --include "*$(date +%Y-%m-%d)*"
```

## Cost Estimate

Estimated monthly costs for this environment:

| Resource | Cost |
|----------|------|
| S3 Storage (2 regions) | $0.05 |
| CloudFront (10GB transfer) | $0.95 |
| Route53 (A record) | $0.00* |
| ACM Certificate | $0.00* |
| CloudWatch | $1.50 |
| **Total** | **~$2.50/month** |

*No additional cost (shared resources)

## Troubleshooting

### Certificate Validation Pending

If ACM certificate remains in "Pending Validation" status:

```bash
# Check DNS validation records
aws acm describe-certificate \
  --certificate-arn $(terraform output -raw acm_certificate_arn)

# Verify Route53 records were created
aws route53 list-resource-record-sets \
  --hosted-zone-id $(aws route53 list-hosted-zones --query "HostedZones[?Name=='synepho.com.'].Id" --output text | cut -d/ -f3) \
  | jq '.ResourceRecordSets[] | select(.Name | contains("aws-services"))'
```

### CORS Errors in Browser

If seeing CORS errors when fetching data:

1. Verify CORS policy applied to data bucket
2. Check bucket policy allows GetObject
3. Verify Origin header matches allowed origins
4. Test with curl as shown in step 4 above

### CloudFront 403 Errors

If seeing 403 errors:

1. Verify S3 bucket policy includes CloudFront OAC
2. Check CloudFront distribution is using correct origins
3. Ensure index.html exists in bucket
4. Verify bucket names match terraform outputs

## Cleanup

To destroy all resources in this environment:

```bash
# Plan destroy
terraform plan -destroy -var-file=environments/aws-services/terraform.tfvars

# Destroy infrastructure
terraform destroy -var-file=environments/aws-services/terraform.tfvars

# Remove state from S3
aws s3 rm s3://synepho-terraform-state/aws-services/terraform.tfstate
```

## References

- Main Infrastructure Repo: https://github.com/jxman/synepho-s3cf-site
- Data Fetcher Project: https://github.com/jxman/aws-infrastructure-fetcher
- Data Contract: https://github.com/jxman/aws-infrastructure-fetcher/blob/main/DATA_CONTRACT.md
