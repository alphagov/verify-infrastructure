resource "aws_eip" "ingress" {
  count = "${var.number_of_availability_zones}"
  vpc   = true
}

resource "aws_eip" "egress" {
  count = "${var.number_of_availability_zones}"
  vpc   = true
}

output "ingress_eip_public_ips" {
  value = "${aws_eip.ingress.*.public_ip}"
}

output "egress_eip_public_ips" {
  value = "${aws_eip.egress.*.public_ip}"
}
