resource "aws_lb" "static_ingress" {
  name                             = "${var.deployment}-static-ingress"
  load_balancer_type               = "network"
  internal                         = false
  enable_cross_zone_load_balancing = true

  subnet_mapping {
    subnet_id     = "${element(aws_subnet.ingress.*id, 0)}"
    allocation_id = "${element(aws_eip.ingress.*.id, 0)}"
  }

  subnet_mapping {
    subnet_id     = "${element(aws_subnet.ingress.*id, 1)}"
    allocation_id = "${element(aws_eip.ingress.*.id, 1)}"
  }

  subnet_mapping {
    subnet_id     = "${element(aws_subnet.ingress.*id, 2)}"
    allocation_id = "${element(aws_eip.ingress.*.id, 2)}"
  }
}

resource "aws_lb_target_group" "static_ingress" {
  name     = "${var.deployment}-static-ingress"
  port     = 4500
  protocol = "TCP"
  vpc_id   = "${aws_vpc.hub.vpc_id}"
}

resource "aws_lb_listener" "static_ingress" {
  load_balancer_arn = "${aws_lb.static_ingress.arn}"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = []
  }
}
