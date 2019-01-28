module "cloudwatch_exporter_ecs_roles" {
  source = "modules/ecs_iam_role_pair"

  deployment       = "${var.deployment}"
  service_name     = "cloudwatch-exporter"
  image_name       = "verify-cloudwatch-exporter"
  tools_account_id = "${var.tools_account_id}"
}

data "template_file" "cloudwatch_exporter_task_def" {
  template = "${file("${path.module}/files/tasks/cloudwatch-exporter.json")}"

  vars {
    image_and_tag = "${local.tools_account_ecr_url_prefix}-verify-cloudwatch-exporter:latest"
    config_base64 = "${base64encode(file("${path.module}/files/prometheus/cloudwatch_exporter.yml"))}"
  }
}

resource "aws_ecs_task_definition" "cloudwatch_exporter" {
  family                = "${var.deployment}-cloudwatch-exporter"
  container_definitions = "${data.template_file.cloudwatch_exporter_task_def.rendered}"
  execution_role_arn    = "${module.cloudwatch_exporter_ecs_roles.execution_role_arn}"
}

resource "aws_ecs_service" "cloudwatch_exporter" {
  name                = "${var.deployment}-cloudwatch-exporter"
  cluster             = "${aws_ecs_cluster.prometheus.id}"
  task_definition     = "${aws_ecs_task_definition.cloudwatch_exporter.arn}"
  scheduling_strategy = "DAEMON"
}
