resource "aws_security_group" "prometheus" {
  name        = "${var.deployment}-prometheus"
  description = "${var.deployment}-prometheus"

  vpc_id = "${aws_vpc.hub.id}"
}
