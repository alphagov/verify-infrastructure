resource "aws_eip" "ingress" {
  count = "${local.number_of_availability_zones}"
  vpc   = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_eip" "egress" {
  count = "${local.number_of_availability_zones}"
  vpc   = true

  lifecycle {
    prevent_destroy = true
  }
}

output "ingress_eip_public_ips" {
  value = "${aws_eip.ingress.*.public_ip}"
}

output "egress_eip_public_ips" {
  value = "${aws_eip.egress.*.public_ip}"
}
