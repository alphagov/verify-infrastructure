locals {
  subnet_bits = 8

  subnet_offsets = {
    ingress  = 20
    internal = 30
    egress   = 40
  }
}

resource "aws_subnet" "ingress" {
  count             = "${var.number_of_availability_zones}"
  vpc_id            = "${aws_vpc.hub.id}"
  availability_zone = "${element(local.azs, count.index)}"

  cidr_block = "${cidrsubnet(
    aws_vpc.hub.cidr_block,
    local.subnet_bits,
    lookup(local.subnet_offsets, "ingress") + count.index
  )}"

  tags {
    Name       = "ingress-${var.deployment}"
    Deployment = "${var.deployment}"
  }
}

resource "aws_subnet" "internal" {
  count             = "${var.number_of_availability_zones}"
  vpc_id            = "${aws_vpc.hub.id}"
  availability_zone = "${element(local.azs, count.index)}"

  cidr_block = "${cidrsubnet(
    aws_vpc.hub.cidr_block,
    local.subnet_bits,
    lookup(local.subnet_offsets, "internal") + count.index
  )}"

  tags {
    Name       = "internal-${var.deployment}"
    Deployment = "${var.deployment}"
  }
}

resource "aws_subnet" "egress" {
  count             = "${var.number_of_availability_zones}"
  vpc_id            = "${aws_vpc.hub.id}"
  availability_zone = "${element(local.azs, count.index)}"

  cidr_block = "${cidrsubnet(
    aws_vpc.hub.cidr_block,
    local.subnet_bits,
    lookup(local.subnet_offsets, "egress") + count.index
  )}"

  tags {
    Name       = "egress-${var.deployment}"
    Deployment = "${var.deployment}"
  }
}
