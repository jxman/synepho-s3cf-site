# Creates the CERT for the site
resource "aws_acm_certificate" "cert" {
  domain_name = var.site_name
  subject_alternative_names = [
  "www.${var.site_name}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Finds the CERT created
data "aws_route53_zone" "cert" {
  name         = var.site_name
  private_zone = false
}

# Created DNS validation recrods from the CERT created above
resource "aws_route53_record" "cert" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.cert.zone_id
}

# Confirms the successful validation of the an ACM Cert created above (waits 60 minutes)
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert : record.fqdn]
  timeouts {
    create = "60m"
  }
}
