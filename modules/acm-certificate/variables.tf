variable "site_name" {
  description = "Domain name for the site"
  type        = string
}

variable "hosted_zone_name" {
  description = "Route53 hosted zone name (defaults to site_name for root domains, use parent domain for subdomains)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
