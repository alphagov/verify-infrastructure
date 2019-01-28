module "metadata_exporter_ecs_roles" {
  source = "modules/ecs_iam_role_pair"

  deployment       = "${var.deployment}"
  service_name     = "metadata-exporter"
  image_name       = "verify-metadata-exporter"
  tools_account_id = "${var.tools_account_id}"
}

data "template_file" "metadata_exporter_task_def" {
  template = "${file("${path.module}/files/tasks/metadata-exporter.json")}"

  vars {
    image_and_tag              = "${local.tools_account_ecr_url_prefix}-verify-metadata-exporter:latest"
    signin_domain              = "${var.signin_domain}"
    deployment                 = "${var.deployment}"
    egress_proxy_url_with_port = "${local.egress_proxy_url_with_protocol}"
  }
}

resource "aws_ecs_task_definition" "metadata_exporter" {
  family                = "${var.deployment}-metadata-exporter"
  container_definitions = "${data.template_file.metadata_exporter_task_def.rendered}"
  execution_role_arn    = "${module.metadata_exporter_ecs_roles.execution_role_arn}"
}

resource "aws_ecs_service" "metadata_exporter" {
  name                = "${var.deployment}-metadata-exporter"
  cluster             = "${aws_ecs_cluster.prometheus.id}"
  task_definition     = "${aws_ecs_task_definition.metadata_exporter.arn}"
  scheduling_strategy = "DAEMON"
}
