resource "aws_ecs_cluster" "fargate-ecs-cluster" {
  name = var.deployment
}

resource "aws_cloudwatch_log_group" "fargate-logs" {
  name              = "${var.deployment}-hub"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_subscription_filter" "csls-subscription" {
  count           = length(var.logging_endpoint_arns)
  name            = "${var.deployment}-hub-csls-${count.index}"
  log_group_name  = aws_cloudwatch_log_group.fargate-logs.name
  filter_pattern  = ""
  destination_arn = var.cls_destination_arn[count.index]
}