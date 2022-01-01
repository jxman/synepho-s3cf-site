# Create the logs bucket for S3 access logging
resource "aws_s3_bucket" "logs" {
  bucket = "${var.site_name}-site-logs"
  acl    = "log-delivery-write"

  #  Lifecycle rules
  lifecycle_rule {
    id      = "logfile cleanup"
    enabled = true

    transition {
      days          = 30
      storage_class = "ONEZONE_IA"
    }
    expiration {
      days = 90
    }
  }
}
