variable "site_name" {
  description = "Domain name for the site"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name (defaults to site_name for root domains, use parent domain for subdomains)"
  type        = string
  default     = null
}

variable "cloudfront_domain_name" {
  description = "The domain name of the CloudFront distribution"
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "The Route 53 zone ID of the CloudFront distribution"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
