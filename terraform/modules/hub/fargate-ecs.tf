resource "aws_ecs_cluster" "fargate-ecs-cluster" {
  name = var.deployment
}
