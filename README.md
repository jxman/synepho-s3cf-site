# Terraform AWS Infrastructure for Synepho.com

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/jxman/synepho-s3cf-site/terraform.yml?branch=main&style=for-the-badge)

This repository contains infrastructure as code (IaC) to deploy and manage a resilient, scalable static website hosting solution on AWS using Terraform.

## Architecture

```text
                        ┌─────────────────┐
                        │     Route53     │
                        │  (DNS Hosting)  │
                        └─────────┬───────┘
                                  │ DNS Resolution
                                  ▼
                        ┌─────────────────┐    ┌─────────────────┐
                        │   CloudFront    │───▶│   CloudWatch    │
                        │  (CDN + HTTPS)  │    │  (Monitoring)   │
                        └─────────┬───────┘    └─────────────────┘
                                  │ Origin Access Control
                                  ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  ACM Certificate│    │   S3 Primary    │    │  S3 Secondary   │
│  (SSL/TLS Cert) │───▶│  (us-east-1)    │◀──▶│  (us-west-2)    │
└─────────────────┘    │   Website       │    │   Failover      │
                       └─────────┬───────┘    └─────────────────┘
                                 │ Cross-Region Replication
                                 ▼
                       ┌─────────────────┐
                       │   S3 Logs       │
                       │ (Access Logs)   │
                       └─────────────────┘
```

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
```

### Quick Start

This project supports multiple environments with pre-configured deployment scripts:

#### Production Deployment

```bash
# Plan production changes
./deploy-prod.sh plan

# Deploy to production (requires confirmation)
./deploy-prod.sh apply
```

#### Development Deployment

```bash
# Plan development changes  
./deploy-dev.sh plan

# Deploy to development
./deploy-dev.sh apply
```

### Manual Configuration

For manual Terraform operations:

```bash
# Initialize with environment-specific backend
terraform init -backend-config=environments/prod/backend.conf

# Plan with environment variables
terraform plan -var-file=environments/prod/terraform.tfvars

# Apply changes
terraform apply -var-file=environments/prod/terraform.tfvars
```

### Environment Configuration

Each environment has its own configuration in the `environments/` directory:

```text
environments/
├── prod/
│   ├── backend.conf       # S3 backend configuration
│   └── terraform.tfvars   # Production variables
├── staging/
│   ├── backend.conf       # Staging backend config
│   └── terraform.tfvars   # Staging variables
└── dev/
    ├── backend.conf       # Development backend config
    └── terraform.tfvars   # Development variables
```

### Website Deployment

After infrastructure is provisioned:

```bash
# Upload website content (example for production)
aws s3 sync ./website/ s3://www.synepho.com/ --delete

# Invalidate CloudFront cache (done automatically by deployment scripts)
aws cloudfront create-invalidation \
  --distribution-id $(terraform output -raw cloudfront_distribution_id) \
  --paths "/*"
```

> **Note:** The deployment scripts automatically invalidate CloudFront cache after successful applies.

## Infrastructure Components

| Component  | Purpose              | Configuration                          |
| ---------- | -------------------- | -------------------------------------- |
| S3 Buckets | Content storage      | Versioning, encryption, logging        |
| CloudFront | Content delivery     | Custom headers, HTTPS, error responses |
| ACM        | TLS certificates     | Auto-renewal, DNS validation           |
| Route53    | DNS management       | A & CNAME records, failover routing    |
| CloudWatch | Monitoring & alerts  | Regional traffic, performance metrics  |
| IAM        | Security permissions | Least privilege access                 |

## Project Structure

```text
.
├── modules/                    # Reusable Terraform modules
│   ├── acm-certificate/        # TLS certificate management
│   ├── cloudfront/            # CDN configuration
│   ├── monitoring/            # CloudWatch dashboards & alarms
│   ├── route53/               # DNS management
│   └── s3-website/            # S3 bucket configuration
├── environments/              # Environment-specific configs
│   ├── prod/                  # Production environment
│   ├── staging/               # Staging environment
│   └── dev/                   # Development environment
├── scripts/                   # Helper scripts
│   ├── create-prerequisites.sh # Creates S3/DynamoDB for state
│   └── README.md              # Script documentation
├── .github/workflows/         # GitHub Actions CI/CD
├── github-actions-iam.tf      # Project-specific IAM for CI/CD
├── deploy-prod.sh             # Production deployment script
├── deploy-dev.sh              # Development deployment script
├── ROADMAP.md                 # Project improvement roadmap
├── main.tf                    # Main infrastructure configuration
├── variables.tf               # Input variable definitions
├── outputs.tf                 # Output value definitions
└── versions.tf                # Provider version constraints
```

## CI/CD & Development Workflow

### GitHub Actions

This project includes automated CI/CD with GitHub Actions:

- **Automatic deployments** on push to `main` branch
- **PR validation** with Terraform plan comments
- **Environment isolation** using the same backend configs as local
- **State management** with S3 + DynamoDB locking
- **OIDC authentication** with project-specific IAM roles for secure deployments
- **Automated CloudFront cache invalidation** after successful deployments

### Development Workflow

1. **Feature Development**

   ```bash
   git checkout -b feature/new-feature main
   ```

2. **Local Testing**

   ```bash
   # Test changes in development environment
   ./deploy-dev.sh plan
   ./deploy-dev.sh apply
   ```

3. **Submit Pull Request**
   - GitHub Actions automatically runs `terraform plan`
   - Plan results are posted as PR comments
   - No infrastructure changes applied during PR

4. **Merge to Main**
   - Automatically triggers production deployment
   - Uses the same state file as local development
   - Full deployment pipeline with validation

## Security

This project implements AWS security best practices:

- ✅ **Private S3 buckets** with CloudFront Origin Access Identity
- ✅ **TLS encryption** for all traffic
- ✅ **Security headers** via CloudFront response headers policy
- ✅ **Access logging** for audit trail
- ✅ **IAM least privilege** for all service roles
- ✅ **Project-specific IAM roles** with OIDC authentication for GitHub Actions
- ✅ **Repository isolation** preventing cross-project access to AWS resources

## Monitoring & Operations

### CloudWatch Dashboard

After deployment, access your monitoring dashboard to view:
- **Regional traffic patterns** - See where your visitors are coming from
- **Performance metrics** - Monitor cache hit rates and latency
- **Error tracking** - Real-time 4xx/5xx error rates
- **Data transfer** - Bandwidth usage and request volumes

🎯 **Live Dashboard**: [synepho-com-traffic-dashboard](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=synepho-com-traffic-dashboard)

Dashboard URL is also provided in Terraform outputs after deployment.

### Monitoring Features

- **Real-time metrics** for CloudFront and S3 performance
- **Automated alerts** for high error rates and poor cache performance
- **Regional traffic analysis** showing visitor distribution by AWS edge location
- **Performance dashboards** with customizable time ranges
- **Access logs** stored in dedicated logging bucket with lifecycle policies
- **Versioning enabled** for recovery from data corruption
- **Automated failover** for region-level resilience

### Key Metrics Monitored

- Request count and bandwidth by region
- Cache hit rates and origin latency
- 4xx and 5xx error percentages
- Origin response times and availability

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

## State Management

### Multi-Environment State Isolation
Each environment maintains its own isolated state:

- **Production**: `synepho-terraform-state` bucket, `synepho-com/terraform.tfstate` key
- **Development**: `synepho-terraform-state-dev` bucket, `terraform.tfstate` key  
- **Staging**: `synepho-terraform-state-staging` bucket, `terraform.tfstate` key

### State Features

- **S3 Backend** with versioning for rollbacks
- **Encryption** for security (AES256)
- **DynamoDB Locking** prevents concurrent modifications
- **Shared State** between local and GitHub Actions (production only)

### Creating State Infrastructure

```bash
# Create S3 buckets and DynamoDB tables for all environments
./scripts/create-prerequisites.sh
```

## Cost Optimization

This architecture is designed to be cost-effective:

- CloudFront origin failover instead of duplicate distributions
- S3 intelligent tiering for infrequently accessed content
- Log lifecycle policies to reduce long-term storage costs

## Compliance & Standards

- Follows [Terraform best practices](https://www.terraform-best-practices.com/)
- Adheres to AWS Well-Architected Framework principles
- Infrastructure as Code for reproducibility and auditing
- Multi-environment support for proper SDLC practices
- Automated testing and validation in CI/CD pipeline

## Additional Resources

- **[ROADMAP.md](ROADMAP.md)** - Detailed improvement roadmap with actionable tasks
- **[environments/README.md](environments/README.md)** - Environment configuration guide
- **[scripts/README.md](scripts/README.md)** - Deployment scripts documentation
- **[.github/workflows/README.md](.github/workflows/README.md)** - CI/CD workflow details

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
