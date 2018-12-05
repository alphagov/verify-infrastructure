resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.hub.id}"

  tags {
    Name        = "public-${var.deployment}"
    Deployment = "${var.deployment}"
  }
}

resource "aws_route" "public" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.hub.id}"
}

resource "aws_route_table_association" "public_ingress" {
  count          = "${var.number_of_availability_zones}"
  subnet_id      = "${element(aws_subnet.ingress.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_route_table_association" "public_egress" {
  count          = "${var.number_of_availability_zones}"
  subnet_id      = "${element(aws_subnet.egress.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_route_table" "private" {
  count = "${var.number_of_availability_zones}"

  vpc_id = "${aws_vpc.hub.id}"

  tags {
    Name        = "private-${var.deployment}"
    Deployment = "${var.deployment}"
  }
}

resource "aws_route" "private_egress" {
  count = "${var.number_of_availability_zones}"

  destination_cidr_block = "0.0.0.0/0"

  route_table_id         = "${element(
    aws_route_table.private.*.id,
    count.index
  )}"

  nat_gateway_id = "${element(
    aws_nat_gateway.static_egress.*.id,
    count.index
  )}"
}

resource "aws_route_table_association" "internal_private" {
  count          = "${var.number_of_availability_zones}"
  subnet_id      = "${element(aws_subnet.internal.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_route_table_association" "egress_proxy_nlb_private" {
  count          = "${var.number_of_availability_zones}"
  subnet_id      = "${element(aws_subnet.internal.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
