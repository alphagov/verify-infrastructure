resource "aws_security_group" "ingress" {
  name        = "${local.service}-ingress"
  description = "${local.service}-ingress"

  vpc_id = "${data.terraform_remote_state.hub.vpc_id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${var.accessible_from_cidrs}"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.accessible_from_cidrs}"]
  }
}

resource "aws_security_group" "egress" {
  name        = "${local.service}-egress"
  description = "${local.service}-egress"

  vpc_id = "${data.terraform_remote_state.hub.vpc_id}"

  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = ["${aws_security_group.self_service.id}"]
  }
}

resource "aws_security_group" "self_service" {
  name        = "${local.service}"
  description = "${local.service} security group for hub VPC"
  vpc_id      = "${data.terraform_remote_state.hub.vpc_id}"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
