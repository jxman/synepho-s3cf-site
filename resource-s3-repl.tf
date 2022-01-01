# Created the IAM role needed for the S3 replication to run
resource "aws_iam_role" "replication" {
  name = "tf-iam-role-replication-${var.site_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

# Created the IAM policy that will be attached to the S3 bucket to allow for replicaton
resource "aws_iam_policy" "replication" {
  name = "tf-iam-role-policy-replication-${var.site_name}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.www_site.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.www_site.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.destination.arn}/*"
    }
  ]
}
POLICY
}

# Attachs the created policy to the role
resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

#Creates the replication bucket in the West region
resource "aws_s3_bucket" "destination" {
  provider = aws.west
  bucket   = "www.${var.site_name}-secondary"
  versioning {
    enabled = true
  }
}

# creates the CF origin access identify to host static S3 site
resource "aws_cloudfront_origin_access_identity" "destination_origin_access_identity" {
  comment = "destination cloudfront origin access identity"
}


# Add the IAM role for CF access to the S3 Bucket
resource "aws_s3_bucket_policy" "destination_site" {
  bucket   = "www.${var.site_name}-secondary"
  policy   = data.aws_iam_policy_document.cf_access_destination.json
  provider = aws.west
}

# Data for the AWS policy
data "aws_iam_policy_document" "cf_access_destination" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.destination_origin_access_identity.iam_arn]
    }
    sid    = "OnlyCloudfrontReadAccess2"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.destination.arn}/*"
    ]
  }
}

