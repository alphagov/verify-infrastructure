resource "aws_security_group" "mgmt_lb" {
  name        = "${var.deployment}-mgmt-lb"
  description = "${var.deployment}-mgmt-lb"

  vpc_id = "${aws_vpc.hub.id}"
}

module "mgmt_lb_can_talk_to_prometheus" {
  source = "modules/microservice_connection"

  source_sg_id      = "${aws_security_group.mgmt_lb.id}"
  destination_sg_id = "${aws_security_group.prometheus.id}"

  port = 9090
}

resource "aws_security_group_rule" "mgmt_lb_ingress_from_internet_over_http" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = "${aws_security_group.mgmt_lb.id}"
  cidr_blocks       = ["${var.publically_accessible_from_cidrs}"]
}

locals {
  mgmt_domain = "mgmt.${local.root_domain}"
}

resource "aws_route53_zone" "mgmt_domain" {
  name = "${local.mgmt_domain}"

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_acm_certificate" "mgmt_wildcard" {
  domain_name       = "${local.mgmt_domain}"
  subject_alternative_names = ["*.${local.mgmt_domain}"]
  validation_method = "DNS"

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_route53_record" "mgmt_wildcard_cert_validation" {
  name    = "${aws_acm_certificate.mgmt_wildcard.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.mgmt_wildcard.domain_validation_options.0.resource_record_type}"
  zone_id = "${aws_route53_zone.mgmt_domain.zone_id}"

  records = [
    "${aws_acm_certificate.mgmt_wildcard.domain_validation_options.0.resource_record_value}",
  ]

  ttl = 60
}

resource "aws_acm_certificate_validation" "mgmt_wildcard" {
  certificate_arn         = "${aws_acm_certificate.mgmt_wildcard.arn}"
  validation_record_fqdns = ["${aws_route53_record.mgmt_wildcard_cert_validation.fqdn}"]
}

resource "aws_lb" "mgmt" {
  name               = "${var.deployment}-mgmt"
  internal           = false
  load_balancer_type = "application"

  security_groups = ["${aws_security_group.mgmt_lb.id}"]
  subnets         = ["${aws_subnet.ingress.*.id}"]

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_lb_listener" "mgmt_http" {
  load_balancer_arn = "${aws_lb.mgmt.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "mgmt_https" {
  load_balancer_arn = "${aws_lb.mgmt.arn}"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = "${aws_acm_certificate.mgmt_wildcard.arn}"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "🛠️"
      status_code  = "200"
    }
  }
}
