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
```

### Configuration

1. Create environment-specific variables:

```bash
cp environments/prod/terraform.tfvars.example environments/prod/terraform.tfvars
```

2. Edit `terraform.tfvars` with your domain and settings:

```hcl
site_name         = "yourdomain.com"
primary_region    = "us-east-1"
secondary_region  = "us-west-1"
environment       = "prod"
```

## Usage

### Deployment

```bash
# Review changes
terraform plan

# Apply infrastructure changes
terraform apply
```

### Website Deployment

After infrastructure is provisioned:

```bash
# Upload website content
aws s3 sync ./website/ s3://www.yourdomain.com/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

## Infrastructure Components

| Component  | Purpose              | Configuration                          |
| ---------- | -------------------- | -------------------------------------- |
| S3 Buckets | Content storage      | Versioning, encryption, logging        |
| CloudFront | Content delivery     | Custom headers, HTTPS, error responses |
| ACM        | TLS certificates     | Auto-renewal, DNS validation           |
| Route53    | DNS management       | A & CNAME records, failover routing    |
| IAM        | Security permissions | Least privilege access                 |

## Module Structure

```
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
```

## Development Workflow

We follow [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/) for development:

1. Create feature branches from `develop`

   ```bash
   git checkout -b feature/new-feature develop
   ```

2. Implement changes with appropriate tests

3. Submit pull requests for review

4. Merge to `develop` after approval

5. Release versions are promoted from `develop` to `main`

## Security

This project implements AWS security best practices:

- ✅ **Private S3 buckets** with CloudFront Origin Access Identity
- ✅ **TLS encryption** for all traffic
- ✅ **Security headers** via CloudFront response headers policy
- ✅ **Access logging** for audit trail
- ✅ **IAM least privilege** for all service roles

## Monitoring & Operations

- CloudWatch metrics for CloudFront and S3
- Access logs stored in dedicated logging bucket
- Versioning enabled for recovery from data corruption
- Automated failover for region-level resilience

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Run Terraform formatting (`terraform fmt -recursive`)
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

### Pre-commit Checks

We use pre-commit hooks for quality control:

```bash
# Install pre-commit
pip install pre-commit

# Install repository hooks
pre-commit install
```

## Terraform State Management

State is stored in an S3 backend with:

- Versioning for rollbacks
- Encryption for security
- DynamoDB table for locking (prevents concurrent modifications)

## Cost Optimization

This architecture is designed to be cost-effective:

- CloudFront origin failover instead of duplicate distributions
- S3 intelligent tiering for infrequently accessed content
- Log lifecycle policies to reduce long-term storage costs

## Compliance & Standards

- Follows [Terraform best practices](https://www.terraform-best-practices.com/)
- Adheres to AWS Well-Architected Framework principles
- Infrastructure as Code for reproducibility and auditing

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
