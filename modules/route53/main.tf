data "aws_route53_zone" "selected" {
  name         = var.hosted_zone_name != null ? var.hosted_zone_name : var.site_name
  private_zone = false
}

# Route53 record for the root domain (no www)
resource "aws_route53_record" "root_site" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.site_name
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

# Route53 record for www subdomain
resource "aws_route53_record" "www_site" {
  zone_id        = data.aws_route53_zone.selected.zone_id
  name           = "www.${var.site_name}"
  type           = "CNAME"
  ttl            = 5
  set_identifier = "live"

  records = [var.site_name]

  weighted_routing_policy {
    weight = 90
  }
}

# Route53 record for cloud status page (Vercel)
resource "aws_route53_record" "cloudstatus_site" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "cloudstatus.${var.site_name}"
  type    = "CNAME"
  ttl     = 300
  records = ["86f00b6411813bbf.vercel-dns-017.com"]
}
