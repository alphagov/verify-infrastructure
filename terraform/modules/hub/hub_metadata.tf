# metadata
#
# frontend applications are run on the ingress asg

resource "aws_security_group" "metadata_task" {
  name        = "${var.deployment}-metadata-task"
  description = "${var.deployment}-metadata-task"

  vpc_id = "${aws_vpc.hub.id}"
}

resource "aws_security_group_rule" "metadata_egress_to_s3_endpoint" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = "${aws_security_group.metadata_task.id}"
  prefix_list_ids   = ["${aws_vpc_endpoint.s3.prefix_list_id}"]
}

data "template_file" "metadata_task_def" {
  template = "${file("${path.module}/files/tasks/metadata.json")}"

  vars {
    deployment    = "${var.deployment}"
    image_and_tag = "${local.tools_account_ecr_url_prefix}-verify-metadata:latest"
  }
}

module "metadata_ecs_roles" {
  source = "modules/ecs_iam_role_pair"

  deployment       = "${var.deployment}"
  service_name     = "metadata"
  tools_account_id = "${var.tools_account_id}"
  image_name       = "verify-nginx-tls"
}

resource "aws_ecs_task_definition" "metadata" {
  family                = "${var.deployment}-metadata"
  container_definitions = "${data.template_file.metadata_task_def.rendered}"
  network_mode          = "awsvpc"
  execution_role_arn    = "${module.metadata_ecs_roles.execution_role_arn}"
}

resource "aws_ecs_service" "metadata" {
  name            = "${var.deployment}-metadata"
  cluster         = "${aws_ecs_cluster.ingress.id}"
  task_definition = "${aws_ecs_task_definition.metadata.arn}"
  desired_count   = 1

  load_balancer {
    target_group_arn = "${aws_lb_target_group.ingress_metadata.arn}"
    container_name   = "nginx"
    container_port   = "8443"
  }

  network_configuration {
    subnets         = ["${aws_subnet.internal.*.id}"]
    security_groups = ["${aws_security_group.metadata_task.id}"]
  }
}
