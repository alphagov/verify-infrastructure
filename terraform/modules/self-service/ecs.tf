locals  {
  hub_deployment = "${var.deployment == "prod" ? "" : "${var.deployment}." }"

  task_vars = {
    image_digest          = var.image_digest
    aws_bucket            = aws_s3_bucket.config_metadata.bucket
    region                = data.aws_region.region.name
    rails_secret_key_base = aws_ssm_parameter.rails_secret_key_base.arn
    database_username     = var.db_username
    database_password_arn = "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/${local.service}/db-master-password"
    database_host         = aws_db_instance.self_service.address
    database_name         = aws_db_instance.self_service.name
    db_command            = var.db_command
    cognito_client_id     = module.cognito.user_pool_client_id
    cognito_user_pool_id  = module.cognito.user_pool_id
    asset_host            = var.asset_host
    asset_prefix          = "${element(split(":", var.image_digest),1)}/assets/"
    sentry_dsn            = "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/${local.service}/sentry-dsn"
    hub_environments      = var.hub_environments
    hub_config_host       = "https://config.${local.hub_deployment}${var.hub_host}:443"
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = local.service
}

data "template_file" "task_def" {
  template = file("${path.module}/files/task-def.json")

  vars = local.task_vars
}

data "template_file" "migrations_task_def" {
  template = file("${path.module}/files/migrations-task-def.json")

  vars = local.task_vars
}

resource "aws_ecs_task_definition" "task_def" {
  family                = local.service
  container_definitions = data.template_file.task_def.rendered
  network_mode          = "awsvpc"
  execution_role_arn    = aws_iam_role.self_service_execution.arn
  task_role_arn         = aws_iam_role.self_service_task.arn

  cpu    = 1024
  memory = 2048

  requires_compatibilities = ["FARGATE"]
}

resource "aws_ecs_task_definition" "migrations_task_def" {
  family                = "${local.service}-migrations"
  container_definitions = data.template_file.migrations_task_def.rendered
  network_mode          = "awsvpc"
  execution_role_arn    = aws_iam_role.self_service_execution.arn
  task_role_arn         = aws_iam_role.self_service_task.arn

  cpu    = 1024
  memory = 2048

  requires_compatibilities = ["FARGATE"]
}


resource "aws_ecs_service" "service" {
  name            = local.service
  task_definition = aws_ecs_task_definition.task_def.arn
  cluster         = aws_ecs_cluster.cluster.id
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.task.id
    container_name   = local.service
    container_port   = "8080"
  }

  network_configuration {
    security_groups = [
      aws_security_group.self_service.id,
      aws_security_group.egress_over_https.id,
      data.terraform_remote_state.hub.outputs.can_connect_to_container_vpc_endpoint,
      aws_security_group.egress_to_db.id
    ]

    subnets = data.terraform_remote_state.hub.outputs.internal_subnet_ids
  }
}

resource "aws_ecs_service" "migrations_service" {
  name            = "${local.service}-migrations"
  task_definition = aws_ecs_task_definition.migrations_task_def.arn
  cluster         = aws_ecs_cluster.cluster.id
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      aws_security_group.egress_over_https.id,
      data.terraform_remote_state.hub.outputs.can_connect_to_container_vpc_endpoint,
      aws_security_group.egress_to_db.id
    ]

    subnets = data.terraform_remote_state.hub.outputs.internal_subnet_ids
  }
}

resource "random_string" "rails_secret_key_base" {
  length  = 128
  special = false
}

 resource "aws_ssm_parameter" "rails_secret_key_base" {
  name        = "/${var.deployment}/${local.service}/rails-secret-key-base"
  description = "Rails secret base for self-service"
  type        = "SecureString"
  key_id      = aws_kms_key.self_service_key.key_id
  value       = random_string.rails_secret_key_base.result
}
