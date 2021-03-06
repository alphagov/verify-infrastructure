resource "aws_security_group" "lb" {
  name        = "${local.identifier}-fargate-lb"
  description = "${local.identifier}-fargate-lb"

  vpc_id = var.vpc_id
}

output "lb_sg_id" {
  value = aws_security_group.lb.id
}

resource "aws_security_group_rule" "task_ingress_from_lb" {
  type     = "ingress"
  protocol = "tcp"

  from_port = 1025
  to_port   = 65535

  security_group_id        = aws_security_group.task.id
  source_security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "lb_egress_to_task" {
  type     = "egress"
  protocol = "tcp"

  from_port = 1025
  to_port   = 65535

  # source is destination for egress
  source_security_group_id = aws_security_group.task.id
  security_group_id        = aws_security_group.lb.id
}

resource "aws_security_group" "task" {
  name        = "${local.identifier}-task"
  description = "${local.identifier}-task"
  vpc_id      = var.vpc_id
}

output "task_sg_id" {
  value = aws_security_group.task.id
}
