data "aws_route53_zone" "account_public_root" {
  name = "${var.domain}"
}

data "aws_acm_certificate" "wildcard" {
  domain      = "${var.domain}"
  statuses    = ["ISSUED"]
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}
