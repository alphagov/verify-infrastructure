resource "aws_security_group" "hub_fargate_microservice" {
  name        = "${var.deployment}-hub-fargate-microservice"
  description = "${var.deployment}-hub-fargate-microservice"

  vpc_id = aws_vpc.hub.id
}
