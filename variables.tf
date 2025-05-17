variable "site_name" {
  description = "Domain name for the site (e.g., synepho.com)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]\\.[a-z]{2,}$", var.site_name))
    error_message = "The site_name must be a valid domain name."
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

locals {
  common_tags = {
    Environment = var.environment
    Project     = "synepho-website"
    ManagedBy   = "terraform"
    Owner       = "johxan"
    Site        = var.site_name
  }
}
