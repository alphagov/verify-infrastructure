resource "aws_lb" "self_service_edge" {
  load_balancer_type = "application"

  name            = "${var.deployment}-${local.service}"
  internal        = false
  security_groups = [
    "${aws_security_group.ingress.id}",
    "${aws_security_group.egress.id}"
  ]

  subnets = ["${data.terraform_remote_state.hub.public_subnet_ids}"]

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_lb_target_group" "task" {
  name                 = "${local.service}-task"
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = "${data.terraform_remote_state.hub.vpc_id}"
  deregistration_delay = 15
  slow_start           = 30

  health_check {
    path     = "/"
    protocol = "HTTP"
    interval = "30"
    timeout  = "15"
    matcher  = "200-401"
  }

  depends_on = [
    "aws_lb.self_service_edge",
  ]
}

resource "aws_lb_listener" "cluster_http" {
  load_balancer_arn = "${aws_lb.self_service_edge.arn}"
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

resource "aws_lb_listener" "cluster_https" {
  load_balancer_arn = "${aws_lb.self_service_edge.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-1-2017-01"

  certificate_arn = "${var.ssl_certificate_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.task.arn}"
  }
}
