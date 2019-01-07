resource "aws_eip" "static_ingress" {
  count = "${var.number_of_availability_zones}"
  vpc   = false
}

resource "aws_lb" "static_ingress" {
  name                             = "static_ingress"
  load_balancer_type               = "network"
  internal                         = false
  enable_cross_zone_load_balancing = true

  subnet_mapping {
    count         = "${var.number_of_availability_zones}"
    subnet_id     = "${element(aws_subnet.ingress.*id, count.index)}"
    allocation_id = "${element(aws_eip.static_ingress.*.id, count.index)}"
  }
}

resource "aws_lb_target_group" "static_ingress" {
  name     = "static_ingress"
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
