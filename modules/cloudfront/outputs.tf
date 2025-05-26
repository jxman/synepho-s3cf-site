output "domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website_cdn.domain_name
}

output "distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.website_cdn.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for cache invalidation"
  value       = module.cloudfront.distribution_id
  sensitive   = false
}

output "hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID"
  value       = aws_cloudfront_distribution.website_cdn.hosted_zone_id
}
