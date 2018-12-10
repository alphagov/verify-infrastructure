# frontend
#
# needs to connect to:
#   - config
#   - saml proxy
#   - policy
#
# frontend applications are run on the ingress asg

resource "aws_security_group" "frontend_task" {
  name        = "${var.deployment}-frontend-task"
  description = "${var.deployment}-frontend-task"

  vpc_id = "${aws_vpc.hub.id}"
}

data "template_file" "frontend_task_def" {
  template = "${file("${path.module}/files/tasks/frontend.json")}"

  vars {
    app           = "frontend"
    image_and_tag = "${local.tools_account_ecr_url_prefix}-verify-frontend:latest"
    domain        = "${var.domain}"
  }
}

module "frontend_ecs_roles" {
  source = "modules/ecs_iam_role_pair"

  deployment       = "${var.deployment}"
  tools_account_id = "${var.tools_account_id}"
  service_name     = "frontend"
  image_name       = "verify-frontend"
}

resource "aws_ecs_task_definition" "frontend" {
  family                = "${var.deployment}-frontend"
  container_definitions = "${data.template_file.frontend_task_def.rendered}"
  network_mode          = "awsvpc"
  execution_role_arn    = "${module.frontend_ecs_roles.execution_role_arn}"
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.deployment}-frontend"
  cluster         = "${aws_ecs_cluster.ingress.id}"
  task_definition = "${aws_ecs_task_definition.frontend.arn}"
  desired_count   = 1

  load_balancer {
    target_group_arn = "${aws_lb_target_group.ingress_frontend.arn}"
    container_name   = "frontend"
    container_port   = "8080"
  }

  network_configuration {
    subnets         = ["${aws_subnet.internal.*.id}"]
    security_groups = ["${aws_security_group.frontend_task.id}"]
  }
}
