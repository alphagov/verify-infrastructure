resource "aws_lb" "cluster" {
  load_balancer_type = "application"

  name            = "${local.identifier}"
  internal        = true
  security_groups = ["${aws_security_group.lb.id}"]
  subnets         = ["${var.lb_subnets}"]

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_lb_target_group" "task" {
  name                 = "${local.identifier}-task"
  port                 = "8443"
  protocol             = "HTTPS"
  target_type          = "instance"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = 15
  slow_start           = 30

  health_check {
    path     = "${var.health_check_path}"
    protocol = "${var.health_check_protocol}"
    interval = "${var.health_check_interval}"
    timeout  = "${var.health_check_timeout}"
    matcher  = "${var.health_check_http_codes}"
  }

  depends_on = [
    "aws_lb.cluster",
  ]
}

resource "aws_lb_listener" "cluster_http" {
  load_balancer_arn = "${aws_lb.cluster.arn}"
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
  load_balancer_arn = "${aws_lb.cluster.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2015-05"
  certificate_arn   = "${var.certificate_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.task.arn}"
  }
}
