resource "aws_security_group" "instance" {
  name        = "${local.identifier}-instance"
  description = "${local.identifier}-instance"

  vpc_id = "${var.vpc_id}"
}

output "instance_sg_id" {
  value = "${aws_security_group.instance.id}"
}
