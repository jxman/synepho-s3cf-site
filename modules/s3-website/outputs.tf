output "primary_bucket_name" {
  description = "Name of the primary S3 bucket"
  value       = aws_s3_bucket.www_site.bucket
}

output "primary_bucket_regional_domain" {
  description = "Regional domain name of the primary S3 bucket"
  value       = aws_s3_bucket.www_site.bucket_regional_domain_name
}

output "failover_bucket_name" {
  description = "Name of the failover S3 bucket"
  value       = aws_s3_bucket.destination.bucket
}

output "failover_bucket_regional_domain" {
  description = "Regional domain name of the failover S3 bucket"
  value       = aws_s3_bucket.destination.bucket_regional_domain_name
}

output "primary_origin_access_identity" {
  description = "CloudFront Origin Access Identity for primary bucket"
  value       = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
}

output "failover_origin_access_identity" {
  description = "CloudFront Origin Access Identity for failover bucket"
  value       = aws_cloudfront_origin_access_identity.destination_origin_access_identity.cloudfront_access_identity_path
}

output "logs_bucket_name" {
  description = "Name of the logs bucket"
  value       = aws_s3_bucket.logs.bucket
}
