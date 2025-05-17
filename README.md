# Terraform Infrastructure for synepho.com

This repository contains the Terraform configuration for hosting the www.synepho.com website on AWS with a highly available, scalable, and secure architecture.

## Architecture Overview

![Architecture Diagram](docs/architecture-diagram.png)

The infrastructure consists of:

- **Primary S3 bucket** in us-east-1 for website content
- **Failover S3 bucket** in us-west-1 for cross-region redundancy
- **CloudFront distribution** with failover configuration
- **ACM Certificate** for HTTPS
- **Route53** DNS configuration
- **Automated cross-region replication** for high availability
- **Security-enhanced headers** via CloudFront policies

## Prerequisites

- Terraform 1.7.0 or newer
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create all required resources
- GitHub account (for CI/CD pipeline)

## Project Structure

terraform-s3cf/
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
├── versions.tf # Terraform version constraints
└── README.md # Project documentation

## Getting Started

### Local Development

1. Clone the repository:
   ```bash
   git clone git@github.com:jxman/terraform-s3cf.git
   cd terraform-s3cf
   ```

Initialize Terraform:
bashterraform init

Create a terraform.tfvars file:
bashcp environments/prod/terraform.tfvars .

# Edit terraform.tfvars to customize variables if needed

Plan the changes:
bashterraform plan

Apply the changes:
bashterraform apply

Working with the CI/CD Pipeline
The repository includes a GitHub Actions workflow that:

Validates Terraform syntax and formatting
Plans changes on pull requests
Applies changes when merged to the master branch

To use the CI/CD pipeline:

Create a feature branch for your changes:
bashgit checkout -b feature/my-change

Make your changes to the Terraform code
Push your changes and create a pull request:
bashgit add .
git commit -m "Description of changes"
git push origin feature/my-change

The GitHub Actions workflow will automatically validate your changes and post the plan as a comment on your PR
Once reviewed and approved, merge the PR to apply the changes

Website Content Deployment
After the infrastructure is provisioned, you can deploy website content to the S3 bucket:
bash# Build your website (example with a static site generator)
npm run build

# Deploy to S3

aws s3 sync ./build/ s3://www.synepho.com/ --delete

# Invalidate CloudFront cache

aws cloudfront create-invalidation --distribution-id $(terraform output -raw cloudfront_distribution_id) --paths "/\*"
Monitoring and Logging

S3 Access Logs: Stored in synepho.com-site-logs bucket
CloudFront Logs: Available through CloudWatch

To access the logs:
bash# Download S3 access logs
aws s3 sync s3://synepho.com-site-logs/www.synepho.com/ ./logs/
Infrastructure Testing
Before applying changes to production, you can test them:
bash# Validate syntax
terraform validate

# Run a plan to see what would change

terraform plan
Maintenance and Updates
Regular maintenance tasks:

Update AWS provider when new versions are released:
bash# Edit versions.tf to update the provider version
terraform init -upgrade

Rotate IAM credentials used for deployments (recommended every 90 days):

Generate new access keys in the AWS console
Update GitHub repository secrets

Check ACM certificate status periodically (certificates should auto-renew)

Disaster Recovery
In case of a major issue with the primary region:

CloudFront will automatically failover to the secondary bucket in us-west-1
To manually force traffic to the failover bucket:
bash# Make primary bucket unavailable
aws s3api put-bucket-policy --bucket www.synepho.com --policy '{"Version": "2012-10-17", "Statement": [{"Effect": "Deny", "Principal": "_", "Action": "s3:_", "Resource": ["arn:aws:s3:::www.synepho.com", "arn:aws:s3:::www.synepho.com/*"]}]}'

To restore normal operation:
bash# Apply original bucket policy
terraform apply -target=module.s3_website.aws_s3_bucket_policy.www_site

Security Considerations
This infrastructure implements several security best practices:

HTTPS-only access via CloudFront
Secure headers configuration
Private S3 buckets with CloudFront Origin Access Identity
Least privilege IAM policies
Cross-region replication for high availability

Contributing

Create a feature branch from master
Make your changes
Format code with terraform fmt -recursive
Validate with terraform validate
Create a pull request
Wait for the CI/CD workflow to validate your changes
Get approval and merge

License
MIT
Contact
For issues or questions, please open a GitHub issue.
