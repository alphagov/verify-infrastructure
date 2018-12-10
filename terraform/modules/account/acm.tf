resource "aws_acm_certificate" "wildcard" {
  domain_name               = "${var.domain}"
  subject_alternative_names = ["*.${var.domain}"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "wildcard_cert_validation" {
  name    = "${aws_acm_certificate.wildcard.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.wildcard.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.public_root.id}"
  records = ["${aws_acm_certificate.wildcard.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "wildcard" {
  certificate_arn         = "${aws_acm_certificate.wildcard.arn}"
  validation_record_fqdns = ["${aws_route53_record.wildcard_cert_validation.fqdn}"]
}
