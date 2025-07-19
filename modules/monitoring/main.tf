# CloudWatch Dashboard for Regional Web Traffic
resource "aws_cloudwatch_dashboard" "website_traffic" {
  dashboard_name = "${replace(var.site_name, ".", "-")}-traffic-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Total Requests"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "BytesDownloaded", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Bytes Downloaded"
          period  = 300
          stat    = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id]
          ]
          view   = "pie"
          region = "us-east-1"
          title  = "Regional Request Distribution"
          period = 3600
          stat   = "Sum"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "CacheHitRate", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Cache Hit Rate (%)"
          period  = 300
          stat    = "Average"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "4xxErrorRate", "DistributionId", var.cloudfront_distribution_id],
            [".", "5xxErrorRate", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Error Rates (%)"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudFront", "OriginLatency", "DistributionId", var.cloudfront_distribution_id]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-1"
          title   = "Origin Latency (ms)"
          period  = 300
          stat    = "Average"
        }
      }
    ]
  })
}

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.site_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "4xxErrorRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "This metric monitors 4xx error rate"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "low_cache_hit_rate" {
  alarm_name          = "${var.site_name}-low-cache-hit-rate"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CacheHitRate"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors cache hit rate"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_origin_latency" {
  alarm_name          = "${var.site_name}-high-origin-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "OriginLatency"
  namespace           = "AWS/CloudFront"
  period              = "300"
  statistic           = "Average"
  threshold           = "1000"
  alarm_description   = "This metric monitors origin latency"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    DistributionId = var.cloudfront_distribution_id
  }

  tags = var.tags
}

# Log Group for CloudFront logs analysis
resource "aws_cloudwatch_log_group" "cloudfront_logs" {
  name              = "/aws/cloudfront/${var.site_name}"
  retention_in_days = 14
  tags              = var.tags
}

# Metric filter to extract regional data from CloudFront logs
resource "aws_cloudwatch_log_metric_filter" "regional_requests" {
  name           = "${var.site_name}-regional-requests"
  log_group_name = aws_cloudwatch_log_group.cloudfront_logs.name
  pattern        = "[timestamp, request_id, client_ip, method, uri, status, bytes, referer, user_agent, edge_location, ...]"

  metric_transformation {
    name          = "RegionalRequests"
    namespace     = "CustomMetrics/${var.site_name}"
    value         = "1"
    default_value = 0
  }
}
