resource "aws_security_group_rule" "egress" {
  type      = "egress"
  from_port = var.port
  to_port   = var.port
  protocol  = "tcp"

  # source means destination for egress
  source_security_group_id = var.destination_sg_id
  security_group_id        = var.source_sg_id
}

resource "aws_security_group_rule" "ingress" {
  type      = "ingress"
  from_port = var.port
  to_port   = var.port
  protocol  = "tcp"

  source_security_group_id = var.source_sg_id
  security_group_id        = var.destination_sg_id
}
