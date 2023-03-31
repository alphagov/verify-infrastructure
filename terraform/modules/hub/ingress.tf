resource "aws_security_group" "ingress" {
  name        = "${var.deployment}-ingress"
  description = "${var.deployment}-ingress"

  vpc_id = aws_vpc.hub.id
}

resource "aws_security_group_rule" "ingress_instance_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = aws_security_group.ingress.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "ingress_instance_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = aws_security_group.ingress.id
  cidr_blocks       = ["0.0.0.0/0"]
}

module "ingress_can_connect_to_frontend_task" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.ingress.id
  destination_sg_id = aws_security_group.frontend_task.id

  port = 8443
}

module "ingress_can_connect_to_metadata_task" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.ingress.id
  destination_sg_id = aws_security_group.metadata_task.id

  port = 8443
}

module "ingress_can_connect_to_analytics_task" {
  source = "./modules/microservice_connection"

  source_sg_id      = aws_security_group.ingress.id
  destination_sg_id = aws_security_group.analytics_task.id

  port = 8443
}

resource "aws_security_group_rule" "ingress_ingress_from_internet_over_http" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = aws_security_group.ingress.id

  cidr_blocks = concat(
    var.publically_accessible_from_cidrs,
    formatlist("%s/32", aws_eip.egress.*.public_ip)
  )
  # adding the egress IPs is a hack to let us access metadata through egress proxy
}

resource "aws_security_group_rule" "ingress_ingress_from_internet_over_https" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = aws_security_group.ingress.id

  cidr_blocks = concat(
    var.publically_accessible_from_cidrs,
    formatlist("%s/32", aws_eip.egress.*.public_ip)
  )
  # adding the egress IPs is a hack to let us access metadata through egress proxy
}

resource "aws_lb_target_group" "ingress_analytics" {
  name                 = "${var.deployment}-ingress-analytics"
  port                 = 8443
  protocol             = "HTTPS"
  vpc_id               = aws_vpc.hub.id
  target_type          = "ip"
  deregistration_delay = 60
  slow_start           = 30

  health_check {
    path     = "/healthcheck"
    protocol = "HTTPS"
    interval = 10
    timeout  = 5
  }
}

resource "aws_lb_target_group" "ingress_metadata" {
  name                 = "${var.deployment}-ingress-metadata"
  port                 = 8443
  protocol             = "HTTPS"
  vpc_id               = aws_vpc.hub.id
  target_type          = "ip"
  deregistration_delay = 60
  slow_start           = 30

  health_check {
    path     = "/healthcheck"
    protocol = "HTTPS"
    interval = 10
    timeout  = 5
  }
}

resource "aws_lb_target_group" "ingress_frontend" {
  name                 = "${var.deployment}-ingress-frontend"
  port                 = 8443
  protocol             = "HTTPS"
  vpc_id               = aws_vpc.hub.id
  target_type          = "ip"
  deregistration_delay = 60
  slow_start           = 30

  health_check {
    path     = "/cookies"
    protocol = "HTTPS"
    interval = 10
    timeout  = 5
    matcher  = "200,301"
  }
}

resource "aws_lb" "ingress" {
  name               = "${var.deployment}-ingress"
  internal           = true
  load_balancer_type = "application"

  security_groups = [aws_security_group.ingress.id]
  subnets         = aws_subnet.internal.*.id

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_lb_listener" "ingress_http" {
  load_balancer_arn = aws_lb.ingress.arn
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

resource "aws_lb_listener" "ingress_https" {
  load_balancer_arn = aws_lb.ingress.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.wildcard_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress_frontend.arn
  }
}

resource "aws_lb_listener_rule" "ingress_metadata_sp" {
  listener_arn = aws_lb_listener.ingress_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress_frontend.arn
  }

  condition {
    path_pattern {
      values = ["/SAML2/metadata/sp"]
    }
  }
}

resource "aws_lb_listener_rule" "ingress_root_staging" {
  count = var.deployment == "staging" ? 1 : 0
  listener_arn = aws_lb_listener.ingress_https.arn
  priority     = 90

  action {
    type = "redirect"

    redirect {
      host        = "www.gov.uk"
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/"]
    }
  }
}

resource "aws_lb_listener_rule" "ingress_root_non_staging" {
  count = var.deployment == "staging" ? 0 : 1
  listener_arn = aws_lb_listener.ingress_https.arn
  priority     = 90

  action {
    type = "redirect"

    redirect {
      path        = "/government/publications/introducing-govuk-verify/introducing-govuk-verify"
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_lb_listener_rule" "ingress_metadata" {
  listener_arn = aws_lb_listener.ingress_https.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress_metadata.arn
  }

  condition {
    path_pattern {
      values = ["/SAML2/metadata/*"]
    }
  }
}

resource "aws_lb_listener_rule" "ingress_analytics" {
  listener_arn = aws_lb_listener.ingress_https.arn
  priority     = 120

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ingress_analytics.arn
  }

  condition {
    path_pattern {
      values = ["/analytics*"]
    }
  }
}

resource "aws_lb_listener_rule" "ingress_metrics" {
  listener_arn = aws_lb_listener.ingress_https.arn
  priority     = 130

  action {
    type = "redirect"

    redirect {
      host        = "www.gov.uk"
      port        = "443"
      path        = "/"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/metrics*"]
    }
  }
}

resource "aws_route53_zone" "ingress_www" {
  name = "www.${local.root_domain}."

  vpc {
    vpc_id = aws_vpc.hub.id
  }

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_route53_record" "ingress_www" {
  name    = var.signin_domain
  type    = "A"
  zone_id = aws_route53_zone.ingress_www.id

  alias {
    name                   = aws_lb.ingress.dns_name
    zone_id                = aws_lb.ingress.zone_id
    evaluate_target_health = true
  }
}

