# Terraform AWS Infrastructure for Synepho.com

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/jxman/synepho-s3cf-site/terraform.yml?branch=main&style=for-the-badge)

This repository contains infrastructure as code (IaC) to deploy and manage a resilient, scalable static website hosting solution on AWS using Terraform.

## Architecture

![AWS Architecture](docs/architecture-diagram.png)

The infrastructure implements a high-availability architecture with:

- **Multi-region redundancy**: Primary resources in us-east-1, failover in us-west-1
- **Content delivery network**: CloudFront distribution for low-latency global access
- **HTTPS**: Automatic TLS certificates with Route53 DNS validation
- **Self-healing**: Automatic failover between regions if primary becomes unavailable

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.7.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials
- [Git](https://git-scm.com/downloads) for version control

## Getting Started

### Installation

```bash
# Clone the repository
git clone https://github.com/jxman/synepho-s3cf-site.git
cd synepho-s3cf-site

# Initialize Terraform
terraform init
Configuration

Create environment-specific variables:

bashcp environments/prod/terraform.tfvars.example environments/prod/terraform.tfvars

Edit terraform.tfvars with your domain and settings:

hclsite_name         = "yourdomain.com"
primary_region    = "us-east-1"
secondary_region  = "us-west-1"
environment       = "prod"
Usage
Deployment
bash# Review changes
terraform plan

# Apply infrastructure changes
terraform apply
Website Deployment
After infrastructure is provisioned:
bash# Upload website content
aws s3 sync ./website/ s3://www.yourdomain.com/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
Infrastructure Components
ComponentPurposeConfigurationS3 BucketsContent storageVersioning, encryption, loggingCloudFrontContent deliveryCustom headers, HTTPS, error responsesACMTLS certificatesAuto-renewal, DNS validationRoute53DNS managementA & CNAME records, failover routingIAMSecurity permissionsLeast privilege access
Module Structure
.
├── modules/               # Reusable components
│   ├── acm-certificate/   # Certificate management
│   ├── cloudfront/        # CDN configuration
│   ├── route53/           # DNS setup
│   └── s3-website/        # Storage configuration
├── environments/          # Environment variables
├── main.tf                # Main entry point
├── variables.tf           # Input definitions
├── outputs.tf             # Output values
└── versions.tf            # Version constraints
Development Workflow
We follow GitFlow for development:

Create feature branches from develop
bashgit checkout -b feature/new-feature develop

Implement changes with appropriate tests
Submit pull requests for review
Merge to develop after approval
Release versions are promoted from develop to main

Security
This project implements AWS security best practices:

✅ Private S3 buckets with CloudFront Origin Access Identity
✅ TLS encryption for all traffic
✅ Security headers via CloudFront response headers policy
✅ Access logging for audit trail
✅ IAM least privilege for all service roles

Monitoring & Operations

CloudWatch metrics for CloudFront and S3
Access logs stored in dedicated logging bucket
Versioning enabled for recovery from data corruption
Automated failover for region-level resilience

Contributing

Fork the repository
Create your feature branch (git checkout -b feature/amazing-feature)
Run Terraform formatting (terraform fmt -recursive)
Commit your changes (git commit -m 'Add some amazing feature')
Push to the branch (git push origin feature/amazing-feature)
Open a Pull Request

Pre-commit Checks
We use pre-commit hooks for quality control:
bash# Install pre-commit
pip install pre-commit

# Install repository hooks
pre-commit install
Terraform State Management
State is stored in an S3 backend with:

Versioning for rollbacks
Encryption for security
DynamoDB table for locking (prevents concurrent modifications)

Cost Optimization
This architecture is designed to be cost-effective:

CloudFront origin failover instead of duplicate distributions
S3 intelligent tiering for infrequently accessed content
Log lifecycle policies to reduce long-term storage costs

Compliance & Standards

Follows Terraform best practices
Adheres to AWS Well-Architected Framework principles
Infrastructure as Code for reproducibility and auditing

License
This project is licensed under the MIT License - see the LICENSE file for details.
Acknowledgments

Terraform AWS Provider documentation
AWS Architecture Center


Note: Replace placeholders (yourdomain.com, GitHub paths) with your actual values before using this README.
```
