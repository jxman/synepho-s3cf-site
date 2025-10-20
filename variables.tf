variable "site_name" {
  description = "Domain name for the site (e.g., synepho.com or aws-services.synepho.com)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]?(\\.[a-z0-9][a-z0-9-]{0,61}[a-z0-9]?)*\\.[a-z]{2,}$", var.site_name))
    error_message = "The site_name must be a valid domain name (supports subdomains like aws-services.synepho.com)."
  }
}

variable "primary_region" {
  description = "Primary AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for failover resources"
  type        = string
  default     = "us-west-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name (for subdomains, use parent domain. e.g., 'synepho.com' for 'aws-services.synepho.com')"
  type        = string
  default     = null
}

variable "enable_cors" {
  description = "Enable CORS configuration for S3 bucket"
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "Allowed CORS origins for S3 bucket"
  type        = list(string)
  default     = ["*"]
}

variable "data_fetcher_lambda_role_arn" {
  description = "IAM role ARN for data fetcher Lambda (optional, only needed for aws-services environment)"
  type        = string
  default     = ""
}

locals {
  common_tags = {
    Environment = var.environment
    Project     = "synepho-website"
    ManagedBy   = "terraform"
    Owner       = "johxan"
    Site        = var.site_name
  }
}
