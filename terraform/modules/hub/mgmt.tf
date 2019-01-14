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

  # default_action {
  #   type = "redirect"

  #   redirect {
  #     port        = "443"
  #     protocol    = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.prometheus.arn}"
  }
}

# resource "aws_lb_listener" "mgmt_https" {
#   load_balancer_arn = "${aws_lb.mgmt.arn}"
#   port              = "443"
#   protocol          = "HTTPS"
#   certificate_arn   = "${local.wildcard_cert_arn}"
# 
#   default_action {
#     type             = "forward"
#     target_group_arn = "${aws_lb_target_group.mgmt_frontend.arn}"
#   }
# }

