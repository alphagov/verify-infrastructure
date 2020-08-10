module "beat_exporter_ecs_roles" {
  source = "./modules/ecs_iam_role_pair"

  deployment       = var.deployment
  service_name     = "beat-exporter"
  image_name       = "verify-beat-exporter"
  tools_account_id = var.tools_account_id
}

data "template_file" "beat_exporter_task_def" {
  template = file("${path.module}/files/tasks/beat-exporter.json")

  vars = {
    image_identifier = "${local.tools_account_ecr_url_prefix}-verify-beat-exporter@${var.beat_exporter_image_digest}"
  }
}

resource "aws_ecs_task_definition" "beat_exporter" {
  family                = "${var.deployment}-beat-exporter"
  container_definitions = data.template_file.beat_exporter_task_def.rendered
  execution_role_arn    = module.beat_exporter_ecs_roles.execution_role_arn
  network_mode          = "host"
}

locals {
  # FIXME is there a better way of doing this?
  clusters = [
    "prometheus",
    "egress-proxy",
    "ingress",
    "static-ingress",
    "saml-soap-proxy",
  ]
}

resource "aws_ecs_service" "beat_exporter" {
  count   = length(local.clusters)
  name    = "${var.deployment}-beat-exporter"
  cluster = "arn:aws:ecs:${data.aws_region.region.name}:${data.aws_caller_identity.account.account_id}:cluster/${var.deployment}-${element(local.clusters, count.index)}"

  #  cluster             = "${element(local.clusters, count.index)}"
  task_definition     = aws_ecs_task_definition.beat_exporter.arn
  scheduling_strategy = "DAEMON"
}
