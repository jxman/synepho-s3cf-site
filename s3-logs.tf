# Create the logs bucket for S3 access logging
resource "aws_s3_bucket" "logs" {
  bucket = "${var.site_name}-site-logs"
  acl    = "log-delivery-write"

  # Testing lifecycle rules
  lifecycle_rule {
    id      = "logfile cleanup"
    enabled = true

    # prefix = "log/"

    # tags = {
    #   rule      = "log"
    #   autoclean = "true"
    # }

    transition {
      days          = 30
      storage_class = "ONEZONE_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
    expiration {
      days = 90
    }
  }
}
