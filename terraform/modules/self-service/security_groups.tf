resource "aws_security_group" "ingress" {
  name        = "${local.service}-ingress"
  description = "${local.service}-ingress"

  vpc_id = data.terraform_remote_state.hub.outputs.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.accessible_from_cidrs
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.accessible_from_cidrs
  }
}

resource "aws_security_group" "egress" {
  name        = "${local.service}-egress"
  description = "${local.service}-egress"

  vpc_id = data.terraform_remote_state.hub.outputs.vpc_id

  egress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.self_service.id]
  }
}

resource "aws_security_group" "self_service" {
  name        = local.service
  description = "${local.service} security group for hub VPC"
  vpc_id      = data.terraform_remote_state.hub.outputs.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "egress_over_https" {
  name        = "${local.service}-egress-over-https"
  description = "${local.service} security group to allow egress over https"
  vpc_id      = data.terraform_remote_state.hub.outputs.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "self_service_ingress_to_config_fargate_v2_lb" {
  type     = "ingress"
  protocol = "tcp"

  from_port = 443
  to_port   = 443

  security_group_id        = data.terraform_remote_state.hub.outputs.config_fargate_v2_lb_sg_id
  source_security_group_id = aws_security_group.egress_over_https.id

  description = "Allows traffic from self-service app to config_fargate_v2"
}

resource "aws_security_group" "egress_to_db" {
  name        = "${local.service}-egress-to-db"
  description = "${local.service} security group connecting to self service db"
  vpc_id      = data.terraform_remote_state.hub.outputs.vpc_id

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress_to_db" {
  name        = "${local.service}-ingress-db"
  description = "Allow inbound access from the self service tasks only"
  vpc_id      = data.terraform_remote_state.hub.outputs.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.egress_to_db.id]
  }
}
