variable "site_name" {
  description = "The name of the website"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for monitoring"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
  default     = ""
}

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}