module "cloudwatch_exporter_ecs_roles" {
  source = "./modules/ecs_iam_role_pair"

  deployment       = var.deployment
  service_name     = "cloudwatch-exporter"
  image_name       = "verify-cloudwatch-exporter"
  tools_account_id = var.tools_account_id
}

data "template_file" "cloudwatch_exporter_task_def" {
  template = file("${path.module}/files/tasks/cloudwatch-exporter.json")

  vars = {
    image_identifier = "${local.tools_account_ecr_url_prefix}-verify-cloudwatch-exporter@${var.cloudwatch_exporter_image_digest}"
    config_base64    = base64encode(file("${path.module}/files/prometheus/cloudwatch_exporter.yml"))
  }
}

resource "aws_ecs_task_definition" "cloudwatch_exporter" {
  family                = "${var.deployment}-cloudwatch-exporter"
  container_definitions = data.template_file.cloudwatch_exporter_task_def.rendered
  execution_role_arn    = module.cloudwatch_exporter_ecs_roles.execution_role_arn
  cpu                   = 462
  memory                = 1024
}

resource "aws_ecs_service" "cloudwatch_exporter" {
  name                = "${var.deployment}-cloudwatch-exporter"
  cluster             = aws_ecs_cluster.prometheus.id
  task_definition     = aws_ecs_task_definition.cloudwatch_exporter.arn
  scheduling_strategy = "DAEMON"
}
