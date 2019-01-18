data "template_file" "cloudwatch_exporter_task_def" {
  template = "${file("${path.module}/files/tasks/cloudwatch-exporter.json")}"

  vars {
    image_and_tag = "prom/cloudwatch-exporter"
    config_base64 = "${base64encode(file("${path.module}/files/prometheus/cloudwatch_exporter.yml"))}"
  }
}

resource "aws_iam_role" "cloudwatch_exporter_readonly" {
  name = "${var.deployment}-cloudwatch-exporter-readonly-task"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "cloudwatch_exporter_readonly" {
  name = "cloudwatch_exporter_readonly"
  role = "${aws_iam_role.cloudwatch_exporter_readonly.id}"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "cloudwatch:Describe*",
                "cloudwatch:Get*",
                "cloudwatch:List*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
  }
  EOF
}

resource "aws_ecs_task_definition" "cloudwatch_exporter" {
  family                = "${var.deployment}-cloudwatch-exporter"
  container_definitions = "${data.template_file.cloudwatch_exporter_task_def.rendered}"
  task_role_arn         = "${aws_iam_role.cloudwatch_exporter_readonly.arn}"
}

resource "aws_ecs_service" "cloudwatch_exporter" {
  name                = "cloudwatch_exporter"
  cluster             = "${aws_ecs_cluster.prometheus.id}"
  task_definition     = "${aws_ecs_task_definition.cloudwatch_exporter.arn}"
  scheduling_strategy = "DAEMON"
}
