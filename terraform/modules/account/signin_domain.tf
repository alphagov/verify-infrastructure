resource "aws_route53_zone" "signin_domain" {
  name = "${var.signin_domain}"

  tags {
    Deployment = "${var.deployment}"
  }
}

output "signin_domain_zone_id" {
  value = "${aws_route53_zone.signin_domain.zone_id}"
}

locals {
  domain_root = "${replace(var.signin_domain, "/^www[.]/", "")}"
}

resource "aws_acm_certificate" "wildcard" {
  domain_name               = "${var.signin_domain}"
  subject_alternative_names = ["*.${local.domain_root}"]
  validation_method         = "DNS"

  tags {
    Deployment = "${var.deployment}"
  }
}
