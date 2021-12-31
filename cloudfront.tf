# Creates CF distrobution
resource "aws_cloudfront_distribution" "website_cdn" {
  enabled      = true
  price_class  = "PriceClass_200"
  http_version = "http1.1"
  aliases      = ["www.${var.site_name}", var.site_name]

  # Origin Group with Failover Config
  origin_group {
    origin_id = "groupS3"

    failover_criteria {
      status_codes = [403, 404, 500, 502]
    }

    member {
      origin_id = "origin-bucket-${aws_s3_bucket.www_site.id}"
    }

    member {
      origin_id = "failoverS3-${aws_s3_bucket.destination.id}"
    }
  }

  # Primary Origin S3
  origin {
    origin_id   = "origin-bucket-${aws_s3_bucket.www_site.id}"
    domain_name = "www.${var.site_name}.s3.us-east-1.amazonaws.com"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  # Secondary S3
  origin {
    origin_id   = "failoverS3-${aws_s3_bucket.destination.id}"
    domain_name = "www.${var.site_name}-secondary.s3.us-west-1.amazonaws.com"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.destination_origin_access_identity.cloudfront_access_identity_path
    }
  }

  default_root_object = "index.html"

  # Cache configs and ttls
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-bucket-${aws_s3_bucket.www_site.id}"

    min_ttl     = "0"
    default_ttl = "300"  //3600
    max_ttl     = "1200" //86400

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # Cert config with ACM Cert
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # Site Error reponses
  custom_error_response {
    error_caching_min_ttl = 5
    error_code            = 403
    response_code         = 403
    response_page_path    = "/404.html"
  }

  custom_error_response {
    error_caching_min_ttl = 5
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"

    }
  }

}

