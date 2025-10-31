# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2025-10-30

### Added
- **SEO Infrastructure Improvements**: CloudFront configuration optimized for search engine indexing
  - Added X-Robots-Tag header to signal search engines for full content indexability
  - Implemented dedicated cache behaviors for robots.txt and sitemap.xml (no caching)
  - Updated custom error responses to return HTTP 200 with index.html for proper SPA routing
  - Changed frame_options from DENY to SAMEORIGIN to allow legitimate iframe embedding

### Changed
- **CloudFront Response Headers Policy**: Added custom_headers_config with SEO-specific headers
- **Error Response Handling**: Modified 403/404 responses to return 200 status code instead of error codes
- **Frame Security Policy**: Updated from DENY to SAMEORIGIN for better embedding support
- **Cache Strategy**: SEO files now bypass cache for immediate search engine updates

### Fixed
- **SPA Routing SEO Issue**: Resolved problem where direct navigation to SPA routes returned 404 status
- **Search Engine Indexing**: Fixed missing X-Robots-Tag header preventing proper indexing

### Documentation
- Updated README.md with CloudFront SEO optimization details
- Updated ROADMAP.md with Phase 2 SEO completion status
- Updated environments/aws-services/README.md with CloudFront feature enhancements
- Added comprehensive SEO changes summary to SEO_IMPROVEMENT_PLAN.md

### Deployment
- Successfully deployed to prod environment (Run #18956621972)
- Successfully deployed to aws-services environment (Run #18956685171)
- Both deployments included automatic CloudFront cache invalidation

## [1.2.0] - 2025-10-20

### Added
- **Lambda Data Fetcher Integration**: S3 bucket policy for Lambda write access
- **CORS Configuration**: Enabled CORS for data file access from dashboard
- **GitHub Actions OIDC Fix**: Bootstrap script to resolve policy attachment issues

### Changed
- **S3 Bucket Policy**: Added conditional Lambda write permissions to /data/* path
- **Security**: Implemented least privilege access for Lambda function

### Documentation
- Created AWS_DATA_FETCHER_INTEGRATION_REQUIREMENTS.md
- Enhanced DEPLOYMENT_TROUBLESHOOTING.md with IAM policy fixes

## [1.1.0] - 2025-10-06

### Added
- **Multi-Environment Infrastructure**: Support for prod, dev, staging, aws-services environments
- **Backend Configuration**: Environment-specific backend configurations
- **GitHub Actions Workflow**: Automated Terraform deployments with environment selection
- **OIDC Authentication**: Secure credential-free AWS access for GitHub Actions

### Changed
- **Deployment Strategy**: Migrated from local scripts to GitHub Actions (recommended)
- **State Management**: Unified state bucket with environment-specific paths
- **IAM Security**: Project-specific roles with repository isolation

### Deprecated
- Local deployment scripts (moved to archived/local-deployment-scripts/)

### Documentation
- Comprehensive README.md overhaul
- Created ROADMAP.md with project improvement plan
- Added environment-specific README files

## [1.0.0] - 2025-06-06

### Added
- Initial infrastructure setup for Synepho.com static website hosting
- S3 buckets with versioning and encryption
- CloudFront distribution with HTTPS
- ACM certificate management with auto-renewal
- Route53 DNS configuration
- CloudWatch monitoring and dashboards
- Multi-region failover support (us-east-1, us-west-1)

### Security
- Origin Access Control (OAC) for S3 buckets
- TLS encryption for all traffic
- Security headers via CloudFront response policy
- Access logging for audit trail
- IAM least privilege permissions

[Unreleased]: https://github.com/jxman/synepho-s3cf-site/compare/v1.3.0...HEAD
[1.3.0]: https://github.com/jxman/synepho-s3cf-site/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/jxman/synepho-s3cf-site/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/jxman/synepho-s3cf-site/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/jxman/synepho-s3cf-site/releases/tag/v1.0.0
