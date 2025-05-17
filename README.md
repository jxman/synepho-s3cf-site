Enhanced README.md for synepho-s3cf-site
I'll create a comprehensive README.md that includes detailed information about your project, along with an AWS infrastructure diagram. Here's the content you can use:
markdown# Synepho.com AWS Infrastructure

This repository contains the Terraform code that defines and manages the AWS infrastructure for the synepho.com website. The infrastructure is designed for high availability, security, and performance.

## Infrastructure Overview

The architecture leverages multiple AWS services across different regions to provide a robust, secure, and high-performance website hosting solution with automatic failover capabilities.

### Key Components

- **Primary S3 Bucket** (us-east-1): Hosts the main website content
- **Secondary S3 Bucket** (us-west-1): Serves as a failover if the primary bucket is unavailable
- **CloudFront Distribution**: Delivers content with low latency via AWS's global CDN network
- **ACM Certificate**: Provides HTTPS encryption for secure communication
- **Route53 DNS**: Manages domain routing and DNS settings
- **Cross-Region Replication**: Automatically synchronizes content between primary and failover buckets

### Infrastructure Diagram

                             ┌───────────────────┐
                             │                   │
                             │    DNS Request    │
                             │                   │
                             └─────────┬─────────┘
                                       │
                                       ▼

┌───────────────────────────────────────────────────────────────────────┐
│ │
│ Route 53 (DNS Service) │
│ │
└───────────────────────────────────┬───────────────────────────────────┘
│
▼
┌───────────────────────────────────────────────────────────────────────┐
│ │
│ CloudFront Distribution (CDN) │
│ TLS Certificate (ACM) │
│ │
└──────────────┬────────────────────────────────────┬──────────────────┘
│ │
│ │ Failover if primary
│ │ returns error codes
▼ ▼
┌─────────────────────────────┐ ┌─────────────────────────────────┐
│ │ │ │
│ Primary S3 Bucket │ │ Secondary S3 Bucket │
│ (us-east-1) │───┐ │ (us-west-1) │
│ │ │ │ │
└─────────────────────────────┘ │ └─────────────────────────────────┘
│
│ Cross-Region Replication
│
▼
┌─────────────────────────────────┐
│ │
│ S3 Access Logs Bucket │
│ (us-east-1) │
│ │
└─────────────────────────────────┘

## Project Structure

synepho-s3cf-site/
├── modules/ # Reusable Terraform modules
│ ├── acm-certificate/ # ACM certificate configuration
│ ├── cloudfront/ # CloudFront distribution setup
│ ├── route53/ # DNS configuration
│ └── s3-website/ # S3 buckets for website hosting
├── environments/ # Environment-specific configurations
│ └── prod/ # Production environment
├── .github/workflows/ # GitHub Actions CI/CD pipeline
├── main.tf # Main Terraform configuration
├── provider.tf # AWS provider configuration
├── variables.tf # Input variables
├── outputs.tf # Output values
└── versions.tf # Terraform version constraints

## Prerequisites

- Terraform 1.7.0 or newer
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create all required resources
- Git for version control

## Getting Started

### Initial Setup

1. Clone this repository:
   ```bash
   git clone https://github.com/jxman/synepho-s3cf-site.git
   cd synepho-s3cf-site
   ```

Initialize Terraform:
bashterraform init

Review and apply changes:
bashterraform plan
terraform apply

Making Changes

Create a new branch for your changes:
bashgit checkout -b feature/your-feature-name

Make your changes to the Terraform files
Format and validate the Terraform code:
bashterraform fmt -recursive
terraform validate

Plan and apply changes:
bashterraform plan
terraform apply

Commit and push your changes:
bashgit add .
git commit -m "Description of changes"
git push origin feature/your-feature-name

Create a pull request on GitHub for review

Website Content Deployment
After the infrastructure is set up, deploy website content using:
bash# Build your website (example with a static site generator)
npm run build

# Deploy to S3

aws s3 sync ./build/ s3://www.synepho.com/ --delete

# Invalidate CloudFront cache

aws cloudfront create-invalidation --distribution-id $(terraform output -raw cloudfront_distribution_id) --paths "/\*"
Failover Testing
To test the failover mechanism:

Make the primary bucket unavailable:
bashaws s3api put-bucket-policy --bucket www.synepho.com --policy '{
"Version": "2012-10-17",
"Statement": [{
"Effect": "Deny",
"Principal": "_",
"Action": "s3:GetObject",
"Resource": ["arn:aws:s3:::www.synepho.com/_"]
}]
}'

Verify content is served from the secondary bucket
Restore access to the primary bucket:
bashterraform apply -target=module.s3_website.aws_s3_bucket_policy.www_site

Monitoring and Maintenance

CloudFront Metrics: Monitor cache hit ratio, error rates, and latency in CloudWatch
S3 Access Logs: Analyze logs in the logging bucket for access patterns and issues
ACM Certificate: Ensure automatic renewal is working properly
Route53 Health Checks: Set up health checks to monitor availability

Security Features

Private S3 Buckets: Content is only accessible through CloudFront
HTTPS Only: All traffic is encrypted via TLS
Security Headers: Implemented via CloudFront response headers policy
Access Logging: All access to the website is logged for auditing

Disaster Recovery
The infrastructure is designed to handle various failure scenarios:

Primary Region Outage: Traffic automatically fails over to the secondary region
Content Corruption: Versioning is enabled on S3 buckets for point-in-time recovery
Configuration Issues: Infrastructure is defined as code and version controlled

License
MIT
Contact
For questions or support, please open an issue in this repository.
