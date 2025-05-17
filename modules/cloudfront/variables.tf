variable "site_name" {
  description = "Domain name for the site"
  type        = string
}

variable "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  type        = string
}

variable "primary_bucket_regional_domain" {
  description = "Regional domain name of the primary S3 bucket"
  type        = string
}

variable "failover_bucket_name" {
  description = "Name of the failover S3 bucket"
  type        = string
}

variable "failover_bucket_regional_domain" {
  description = "Regional domain name of the failover S3 bucket"
  type        = string
}

variable "primary_origin_access_identity" {
  description = "CloudFront Origin Access Identity path for primary bucket"
  type        = string
}

variable "failover_origin_access_identity" {
  description = "CloudFront Origin Access Identity path for failover bucket"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of ACM certificate"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
