data "template_file" "cloudwatch_exporter_task_def" {
  template = "${file("${path.module}/files/tasks/cloudwatch-exporter.json")}"

  vars {
    image_and_tag = "prom/cloudwatch-exporter"
    config_base64 = "${base64encode(file("${path.module}/files/prometheus/cloudwatch_exporter.yml"))}"
  }
}

resource "aws_ecs_task_definition" "cloudwatch_exporter" {
  family                = "${var.deployment}-cloudwatch-exporter"
  container_definitions = "${data.template_file.cloudwatch_exporter_task_def.rendered}"
}

resource "aws_ecs_service" "cloudwatch_exporter" {
  name                = "${var.deployment}-cloudwatch-exporter"
  cluster             = "${aws_ecs_cluster.prometheus.id}"
  task_definition     = "${aws_ecs_task_definition.cloudwatch_exporter.arn}"
  scheduling_strategy = "DAEMON"
}
