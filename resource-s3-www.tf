# Create the www site bucket
resource "aws_s3_bucket" "www_site" {
  bucket = "www.${var.site_name}"

  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.logs.bucket
    target_prefix = "www.${var.site_name}/"
  }

  # website {
  #   index_document = "index.html"
  # }

  replication_configuration {
    role = aws_iam_role.replication.arn
    rules {

      id     = "Full Replication Rule"
      prefix = ""
      status = "Enabled"

      destination {
        bucket        = aws_s3_bucket.destination.arn
        storage_class = "STANDARD"
      }
    }
  }
}

# creates the CF origin access identify to host static S3 site
resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "cloudfront origin access identity"
}

# Add the IAM role for CF access to the S3 Bucket
resource "aws_s3_bucket_policy" "www_site" {
  bucket = "www.${var.site_name}"
  policy = data.aws_iam_policy_document.cf_access.json
}

# Data for the AWS policy
data "aws_iam_policy_document" "cf_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn]
    }
    sid    = "OnlyCloudfrontReadAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.www_site.arn}/*"

    ]
  }
}
