resource "aws_lb" "cluster" {
  load_balancer_type = "application"

  name            = "${local.identifier}"
  internal        = true
  security_groups = ["${aws_security_group.lb.id}"]
  subnets         = ["${var.task_subnets}"]

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_lb_target_group" "task" {
  name                 = "${local.identifier}-task"
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = 60

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
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.task.arn}"
  }
}
