# Logs bucket
resource "aws_s3_bucket" "logs" {
  bucket = "${var.site_name}-site-logs"
  tags   = merge(var.tags, { Name = "${var.site_name}-site-logs" })
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logfile-cleanup"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "ONEZONE_IA"
    }

    expiration {
      days = 90
    }
  }
}

# Primary website bucket
resource "aws_s3_bucket" "www_site" {
  bucket = "www.${var.site_name}"
  tags   = merge(var.tags, { Name = "www.${var.site_name}" })
}

resource "aws_s3_bucket_versioning" "www_site" {
  bucket = aws_s3_bucket.www_site.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_logging" "www_site" {
  bucket        = aws_s3_bucket.www_site.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "www.${var.site_name}/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "www_site" {
  bucket = aws_s3_bucket.www_site.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront Origin Access Identity for primary bucket
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "cloudfront origin access identity for ${var.site_name}"
}

# Failover bucket (secondary region)
resource "aws_s3_bucket" "destination" {
  provider = aws.west
  bucket   = "www.${var.site_name}-secondary"
  tags     = merge(var.tags, { Name = "www.${var.site_name}-secondary" })
}

resource "aws_s3_bucket_versioning" "destination" {
  provider = aws.west
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "destination" {
  provider = aws.west
  bucket   = aws_s3_bucket.destination.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudFront Origin Access Identity for secondary bucket
resource "aws_cloudfront_origin_access_identity" "destination_origin_access_identity" {
  comment = "destination cloudfront origin access identity for ${var.site_name}"
}

# IAM Role for replication
resource "aws_iam_role" "replication" {
  name = "tf-iam-role-replication-${var.site_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy for replication
resource "aws_iam_policy" "replication" {
  name = "tf-iam-role-policy-replication-${var.site_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.www_site.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.www_site.arn}/*"
        ]
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.destination.arn}/*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# Configure replication
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.www_site]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.www_site.id

  rule {
    id     = "Full-Replication-Rule"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"
    }
  }
}

# Primary bucket policy for CloudFront access
data "aws_iam_policy_document" "cf_access" {
  statement {
    sid       = "OnlyCloudfrontReadAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.www_site.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "www_site" {
  bucket = aws_s3_bucket.www_site.id
  policy = data.aws_iam_policy_document.cf_access.json
}

# Secondary bucket policy for CloudFront access
data "aws_iam_policy_document" "cf_access_destination" {
  statement {
    sid       = "OnlyCloudfrontReadAccess2"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.destination.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.destination_origin_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "destination_site" {
  provider = aws.west
  bucket   = aws_s3_bucket.destination.id
  policy   = data.aws_iam_policy_document.cf_access_destination.json
}
