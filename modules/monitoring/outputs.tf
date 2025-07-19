output "dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.primary_region}.console.aws.amazon.com/cloudwatch/home?region=${var.primary_region}#dashboards:name=${aws_cloudwatch_dashboard.website_traffic.dashboard_name}"
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.website_traffic.dashboard_name
}

output "log_group_name" {
  description = "CloudWatch log group name for CloudFront logs"
  value       = aws_cloudwatch_log_group.cloudfront_logs.name
}