resource "aws_internet_gateway" "hub" {
  vpc_id = "${aws_vpc.hub.id}"

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_nat_gateway" "static_egress" {
  count = "${local.number_of_availability_zones}"

  allocation_id = "${element(aws_eip.egress.*.id,    count.index)}"
  subnet_id     = "${element(aws_subnet.egress.*.id, count.index)}"

  depends_on = ["aws_internet_gateway.hub"]

  tags {
    Deployment = "${var.deployment}"
  }
}
