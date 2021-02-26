module "ecs_roles" {
  source = "../ecs_iam_role_pair"

  deployment       = var.deployment
  service_name     = "${var.app}-fargate"
  tools_account_id = var.tools_account_id
  image_name       = var.image_name
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${local.identifier}-fargate"
  container_definitions    = var.task_definition
  execution_role_arn       = module.ecs_roles.execution_role_arn
  task_role_arn            = module.ecs_roles.task_role_arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
}

output "task_role_name" {
  value = module.ecs_roles.task_role_name
}

output "execution_role_name" {
  value = module.ecs_roles.execution_role_name
}

resource "aws_ecs_service" "app" {
  name            = local.identifier
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.app.arn

  desired_count                      = var.number_of_tasks
  deployment_minimum_healthy_percent = var.deployment_min_healthy_percent
  deployment_maximum_percent         = var.deployment_max_percent

  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  load_balancer {
    target_group_arn = aws_lb_target_group.task.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  network_configuration {
    subnets = var.subnets
    security_groups = concat(
      var.additional_task_security_group_ids,
      [aws_security_group.task.id],
    )
  }

  service_registries {
    registry_arn = aws_service_discovery_service.app.arn
    port         = var.container_port
  }
}
