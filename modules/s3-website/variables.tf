variable "site_name" {
  description = "Domain name for the site"
  type        = string
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "Secondary AWS region for failover"
  type        = string
  default     = "us-west-1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_cors" {
  description = "Enable CORS configuration for the bucket"
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "Allowed CORS origins for S3 bucket"
  type        = list(string)
  default     = ["*"]
}
