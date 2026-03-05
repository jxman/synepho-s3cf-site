# Terraform AWS Infrastructure for Synepho.com

[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-%23FF9900.svg?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com/)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/jxman/synepho-s3cf-site/terraform.yml?branch=main&style=for-the-badge)

This repository contains infrastructure as code (IaC) to deploy and manage resilient, scalable static website hosting solutions on AWS using Terraform.

## Active Deployments

- 🌐 **Production**: https://synepho.com (Root domain)
- 🌐 **Development**: https://dev.synepho.com (Development site)
- 🌐 **AWS Services Dashboard**: https://aws-services.synepho.com (Infrastructure dashboard)

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

### Prerequisites Setup

**One-time setup**: Before deploying via GitHub Actions, run the OIDC bootstrap script to set up secure authentication:

```bash
# Run OIDC bootstrap (only needed once)
chmod +x scripts/bootstrap-oidc.sh
./scripts/bootstrap-oidc.sh
```

This creates:
- GitHub Actions OIDC provider in AWS
- IAM role with least-privilege permissions
- Project-specific access policies

### Deployment Methods

#### GitHub Actions (Recommended)

The primary deployment method uses GitHub Actions with OIDC authentication:

```bash
# Deploy any environment via GitHub Actions
gh workflow run "Terraform Deployment" -f environment=prod
gh workflow run "Terraform Deployment" -f environment=dev
gh workflow run "Terraform Deployment" -f environment=aws-services

# Monitor deployment progress
gh run watch

# View recent deployments
gh run list --limit 5
```

**Automatic deployments** also trigger on push to `main` branch.

#### Local Development & Testing

For local Terraform operations (planning and validation only):

```bash
# Initialize with environment-specific backend
terraform init -backend-config=environments/prod/backend.conf

# Plan with environment variables
terraform plan -var-file=environments/prod/terraform.tfvars

# Validate configuration
terraform validate
```

> **⚠️ Important**: All production deployments should use GitHub Actions for audit trail and consistency. Local deployments are discouraged except for development and testing.

### Environment Configuration

Each environment has its own configuration in the `environments/` directory:

```text
environments/
├── prod/
│   ├── backend.conf       # S3 backend configuration
│   └── terraform.tfvars   # Production variables (synepho.com)
├── dev/
│   ├── backend.conf       # Development backend config
│   └── terraform.tfvars   # Development variables (dev.synepho.com)
├── staging/
│   ├── backend.conf       # Staging backend config
│   └── terraform.tfvars   # Staging variables
└── aws-services/
    ├── backend.conf       # AWS services backend config
    ├── terraform.tfvars   # Dashboard variables (aws-services.synepho.com)
    └── data-bucket-cors.json  # CORS config for data access
```

#### Subdomain Support

This infrastructure supports both root domains and subdomains:

- **Root domain**: `synepho.com` - Uses hosted zone with same name
- **Subdomains**: `dev.synepho.com`, `aws-services.synepho.com` - Uses parent domain hosted zone

When configuring subdomains, set `hosted_zone_name` to the parent domain:

```hcl
# environments/aws-services/terraform.tfvars
site_name        = "aws-services.synepho.com"  # The subdomain
hosted_zone_name = "synepho.com"                # Parent domain for DNS
```

### Website Deployment

After infrastructure is provisioned, upload your website content:

```bash
# Get the bucket name from Terraform outputs
BUCKET_NAME=$(terraform output -raw primary_s3_bucket)

# Upload website content
aws s3 sync ./website/ s3://${BUCKET_NAME}/ --delete

# Invalidate CloudFront cache
DISTRIBUTION_ID=$(terraform output -raw cloudfront_distribution_id)
aws cloudfront create-invalidation \
  --distribution-id ${DISTRIBUTION_ID} \
  --paths "/*"
```

#### Example: Deploy AWS Services Dashboard

```bash
# The aws-services environment hosts a React dashboard
cd /path/to/react-app
npm run build

# Upload to S3
aws s3 sync build/ s3://www.aws-services.synepho.com/ --delete

# Invalidate cache
aws cloudfront create-invalidation \
  --distribution-id EBTYLWOK3WVOK \
  --paths "/*"
```

> **Note:** GitHub Actions workflow automatically invalidates CloudFront cache after successful Terraform deployments.

## Infrastructure Components

| Component  | Purpose              | Configuration                          |
| ---------- | -------------------- | -------------------------------------- |
| S3 Buckets | Content storage      | Versioning, encryption, logging        |
| CloudFront | Content delivery     | SEO headers, SPA routing, cache behaviors |
| ACM        | TLS certificates     | Auto-renewal, DNS validation           |
| Route53    | DNS management       | A & CNAME records, failover routing    |
| CloudWatch | Monitoring & alerts  | Regional traffic, performance metrics  |
| IAM        | Security permissions | Least privilege access                 |

### CloudFront SEO Optimizations

The CloudFront distribution includes SEO-optimized configurations:

- **X-Robots-Tag Header**: Signals to search engines that all content is indexable
- **SPA Routing Support**: Returns 200 status with index.html for proper React Router handling
- **SEO File Caching**: Dedicated cache behaviors for robots.txt and sitemap.xml with no caching
- **Frame Options**: SAMEORIGIN policy allows legitimate iframe embedding
- **Custom Error Responses**: 403/404 errors return 200 with index.html for optimal SEO

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
│   ├── prod/                  # Production (synepho.com)
│   ├── dev/                   # Development (dev.synepho.com)
│   ├── staging/               # Staging environment
│   └── aws-services/          # AWS dashboard (aws-services.synepho.com)
│       ├── backend.conf       # State configuration
│       ├── terraform.tfvars   # Environment variables
│       ├── data-bucket-cors.json  # CORS configuration
│       └── README.md          # Environment-specific docs
├── scripts/                   # Helper scripts
│   ├── bootstrap-oidc.sh      # One-time OIDC setup for GitHub Actions
│   ├── create-prerequisites.sh # Creates S3/DynamoDB for state
│   └── README.md              # Script documentation
├── archived/                  # Deprecated scripts (historical reference)
│   └── local-deployment-scripts/
│       ├── deploy-prod.sh     # DEPRECATED: Use GitHub Actions
│       ├── deploy-dev.sh      # DEPRECATED: Use GitHub Actions
│       └── deploy-staging.sh  # DEPRECATED: Use GitHub Actions
├── .github/workflows/         # GitHub Actions CI/CD
│   └── terraform.yml          # Deployment workflow (supports all envs)
├── ROADMAP.md                 # Project improvement roadmap
├── main.tf                    # Main infrastructure configuration
├── variables.tf               # Input variable definitions (with subdomain support)
├── outputs.tf                 # Output value definitions
└── versions.tf                # Provider version constraints
```

## CI/CD & Development Workflow

### GitHub Actions

This project uses GitHub Actions for automated CI/CD:

- ✅ **OIDC Authentication** - Secure, credential-free AWS access using OpenID Connect
- ✅ **Multi-environment support** - Deploy to prod, dev, staging, or aws-services
- ✅ **Manual deployments** - Trigger via `gh` CLI or GitHub UI with environment selection
- ✅ **Automatic deployments** - Triggered on push to `main` branch
- ✅ **PR validation** - Terraform plan runs on pull requests (no apply)
- ✅ **State management** - S3 backend with DynamoDB locking
- ✅ **Cache invalidation** - Automated CloudFront cache clearing after deployments
- ✅ **Project isolation** - Dedicated IAM role prevents cross-repository access

#### Workflow Triggers

```yaml
# Manual deployment (any environment)
workflow_dispatch:
  inputs:
    environment:
      - prod
      - dev
      - staging
      - aws-services

# Automatic deployment (push to main)
push:
  branches: [main]
```

### Development Workflow

1. **Feature Development**

   ```bash
   git checkout -b feature/new-feature main
   ```

2. **Local Testing & Validation**

   ```bash
   # Initialize and plan locally
   terraform init -backend-config=environments/dev/backend.conf
   terraform plan -var-file=environments/dev/terraform.tfvars

   # Validate formatting
   terraform fmt -recursive
   terraform validate
   ```

3. **Deploy to Development**

   ```bash
   # Deploy via GitHub Actions (recommended)
   gh workflow run "Terraform Deployment" -f environment=dev

   # Monitor progress
   gh run watch
   ```

4. **Submit Pull Request**
   - GitHub Actions automatically runs `terraform plan`
   - Plan results are posted as PR comments
   - No infrastructure changes applied during PR
   - Reviewers can see exact changes before merge

5. **Merge to Main**
   - Automatically triggers production deployment
   - Full deployment pipeline with validation
   - CloudFront cache automatically invalidated

## Security

This project implements AWS security best practices:

- ✅ **Private S3 buckets** with CloudFront Origin Access Control (OAC)
- ✅ **TLS encryption** for all traffic with strict transport security
- ✅ **Security headers** via CloudFront response headers policy (CSP, XSS protection, frame options)
- ✅ **SEO headers** for proper search engine indexing (X-Robots-Tag)
- ✅ **Access logging** for audit trail
- ✅ **IAM least privilege** for all service roles
- ✅ **Project-specific IAM roles** with OIDC authentication for GitHub Actions
- ✅ **Repository isolation** preventing cross-project access to AWS resources
- ✅ **Geo-restriction** blocking high-risk countries at the CloudFront edge

### Geo-Restriction

CloudFront native geo-blocking (`blacklist` mode) is enforced for the following countries, selected based on threat intelligence from CrowdStrike, Mandiant, and CISA advisories:

| Country | Code | Primary Threat |
|---------|------|----------------|
| China | `CN` | State-sponsored APT groups (APT41, APT10), mass scanning, IP theft |
| Russia | `RU` | Ransomware groups (LockBit, BlackCat), state actors (Sandworm, Cozy Bear) |
| Iran | `IR` | State-sponsored (APT33, APT34), destructive malware campaigns |
| North Korea | `KP` | Lazarus Group — financially motivated, cryptocurrency theft, supply chain attacks |
| Belarus | `BY` | Operates in close coordination with Russian state actors (Sandworm infrastructure) |
| Nigeria | `NG` | Dominant source of BEC fraud, credential stuffing, web scanning campaigns |
| Vietnam | `VN` | APT32 (OceanLotus) — active web compromise campaigns, high scanning volume |
| Pakistan | `PK` | APT36 (Transparent Tribe) — persistent web attacks |
| Romania | `RO` | Historically high cybercrime rates — botnets, carding |
| Bangladesh | `BD` | High-volume botnet traffic, DDoS participation, credential attacks |

**Implementation notes:**
- Blocking is enforced at the CloudFront edge — requests never reach S3
- CloudFront uses MaxMind GeoIP (~99% accuracy at country level)
- Blocked requests receive HTTP 403; no origin cost is incurred
- This is a no-cost feature included with CloudFront (no WAF required)
- For enhanced blocking with request logging, the `web_acl_id` variable supports future WAF integration

## Monitoring & Operations

### CloudWatch Dashboard

After deployment, access monitoring dashboards to view:
- **Regional traffic patterns** - See where your visitors are coming from
- **Performance metrics** - Monitor cache hit rates and latency
- **Error tracking** - Real-time 4xx/5xx error rates
- **Data transfer** - Bandwidth usage and request volumes

#### Live Dashboards

Each environment has its own CloudWatch dashboard:

- 🎯 **Production**: [synepho-com-traffic-dashboard](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=synepho-com-traffic-dashboard)
- 🎯 **AWS Services**: [aws-services-synepho-com-traffic-dashboard](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=aws-services-synepho-com-traffic-dashboard)

Dashboard URLs are also available in Terraform outputs:
```bash
terraform output dashboard_url
```

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
Each environment maintains its own isolated state in the shared `synepho-terraform-state` bucket:

- **Production**: `synepho-com/terraform.tfstate` - Main site (synepho.com)
- **Development**: `dev/terraform.tfstate` - Dev site (dev.synepho.com)
- **AWS Services**: `aws-services/terraform.tfstate` - Dashboard (aws-services.synepho.com)
- **Staging**: `staging/terraform.tfstate` - Staging environment

### State Features

- ✅ **S3 Backend** with versioning for rollbacks
- ✅ **Encryption** at rest (AES256)
- ✅ **DynamoDB Locking** prevents concurrent modifications
- ✅ **Shared State** between local development and GitHub Actions
- ✅ **Environment isolation** prevents cross-environment conflicts

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

### AWS Tagging Standards

**Status:** ✅ **Fully Compliant** (as of December 12, 2024)

All AWS resources are tagged according to organizational standards with **10 required tags**:

| Tag | Purpose | Example Value |
|-----|---------|---------------|
| `Environment` | Deployment environment | `prod`, `dev`, `staging` |
| `ManagedBy` | Infrastructure management tool | `terraform` |
| `Owner` | Resource owner | `John Xanthopoulos` |
| `Project` | Project identifier (CamelCase) | `SynephoWebsite` |
| `Service` | Service category | `StaticHosting` |
| `GithubRepo` | Source repository | `synepho-s3cf-site` |
| `Site` | Domain name | `synepho.com` |
| `BaseProject` | Parent project | `PersonalWebsite` |
| `SubService` | Service component | `ContentDelivery` |
| `Name` | Resource-specific identifier | `synepho.com-cloudfront-distribution` |

**Benefits:**
- **Cost Allocation**: Track expenses by Project, Service, and SubService
- **Resource Discovery**: Find resources by GithubRepo or BaseProject
- **Compliance**: Meet organizational tagging requirements
- **Automation**: Consistent naming for scripts and tools
- **Documentation**: Self-documenting infrastructure

**Implementation:**
- Tags defined in `variables.tf` as `common_tags` locals
- Applied automatically to all resources via module inheritance
- Verified via Terraform plan before each deployment
- See `TERRAFORM_AWS_IMPROVEMENTS.md` for improvement tracking

## Deployed Sites

### Production Environments

| Environment | URL | Purpose | CloudFront ID | Status |
|-------------|-----|---------|---------------|--------|
| **Production** | https://synepho.com | Main website | - | ✅ Live |
| **Development** | https://dev.synepho.com | Development site | - | ✅ Live |
| **AWS Services** | https://aws-services.synepho.com | Infrastructure dashboard | EBTYLWOK3WVOK | ✅ Live |

### Quick Access

```bash
# View all Terraform outputs for a specific environment
terraform init -backend-config=environments/aws-services/backend.conf
terraform output

# Check site status
curl -I https://aws-services.synepho.com

# View CloudFront distribution
aws cloudfront get-distribution --id EBTYLWOK3WVOK | jq '.Distribution.Status'
```

### Data API Integration

The **AWS Services Dashboard** provides public data endpoints for AWS infrastructure information:

#### Public Data Endpoints

- **Complete Data**: `https://aws-services.synepho.com/data/complete-data.json` (239 KB)
  - Full AWS infrastructure dataset with regions, services, and mappings
- **Regions**: `https://aws-services.synepho.com/data/regions.json` (9.6 KB)
  - AWS region metadata and availability
- **Services**: `https://aws-services.synepho.com/data/services.json` (32 KB)
  - AWS service catalog and descriptions

#### Data Features

- **CDN Distribution**: Files served via CloudFront for global low-latency access
- **CORS Enabled**: Configured for cross-origin requests from approved domains
- **Update Frequency**: Daily at 2 AM UTC via Lambda automation
- **Caching**: 5-minute TTL with automatic cache invalidation on updates
- **Security**: Read-only public access, write access restricted to Lambda function

#### Lambda Integration

Data files are automatically updated by the `aws-data-fetcher` Lambda function:
- **Source Bucket**: `aws-data-fetcher-output` (Lambda output)
- **Distribution Bucket**: `www.aws-services.synepho.com/data/` (CloudFront origin)
- **Lambda Role**: `sam-aws-services-fetch-DataFetcherFunctionRole-pJv38M2Owo8h`
- **Permissions**: Lambda can write to `/data/*` path only (least privilege)

#### CORS Configuration

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

#### Example Usage

```javascript
// Fetch complete AWS data
fetch('https://aws-services.synepho.com/data/complete-data.json')
  .then(response => response.json())
  .then(data => console.log(data));

// Check data freshness
fetch('https://aws-services.synepho.com/data/complete-data.json', {
  method: 'HEAD'
})
  .then(response => {
    const lastModified = response.headers.get('last-modified');
    const etag = response.headers.get('etag');
    console.log(`Last updated: ${lastModified}, ETag: ${etag}`);
  });
```

## Troubleshooting

For common deployment issues and solutions, see **[DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md)**

Common issues covered:
- GitHub Actions deployment failures
- IAM permission issues
- Terraform state problems
- CloudFront 403 errors
- CORS configuration issues
- Lambda write access problems

## Additional Resources

- **[ROADMAP.md](ROADMAP.md)** - Detailed improvement roadmap with actionable tasks
- **[DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md)** - Common deployment issues and solutions
- **[AWS_DATA_FETCHER_INTEGRATION_REQUIREMENTS.md](AWS_DATA_FETCHER_INTEGRATION_REQUIREMENTS.md)** - Lambda data fetcher integration documentation
- **[environments/README.md](environments/README.md)** - Environment configuration guide
- **[environments/aws-services/README.md](environments/aws-services/README.md)** - AWS Services Dashboard deployment guide
- **[scripts/README.md](scripts/README.md)** - Helper scripts documentation
- **[.github/workflows/README.md](.github/workflows/README.md)** - CI/CD workflow details

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Architecture Center](https://aws.amazon.com/architecture/)
