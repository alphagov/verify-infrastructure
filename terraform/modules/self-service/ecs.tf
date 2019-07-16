resource "aws_ecs_cluster" "cluster" {
  name = "${local.service}"
}

data "template_file" "task_def" {
  template = "${file("${path.module}/files/task-def.json")}"

  vars = {
    aws_account_id = "${data.aws_caller_identity.account.account_id}"
  }
}

resource "aws_ecs_task_definition" "task_def" {
  family                = "${local.service}"
  container_definitions = "${data.template_file.task_def.rendered}"
  network_mode          = "awsvpc"
  execution_role_arn    = "${aws_iam_role.self_service_execution.arn}"
  task_role_arn         = "${aws_iam_role.self_service_task.arn}"

  cpu    = 1024
  memory = 2048

  requires_compatibilities = ["FARGATE"]
}


resource "aws_ecs_service" "service" {
  name            = "${local.service}"
  task_definition = "${aws_ecs_task_definition.task_def.arn}"
  cluster         = "${aws_ecs_cluster.cluster.id}"
  desired_count   = 2
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.task.id}"
    container_name   = "${local.service}"
    container_port   = "8080"
  }

  network_configuration {
    security_groups = [
      "${aws_security_group.self_service.id}",
      "${data.terraform_remote_state.hub.can_connect_to_container_vpc_endpoint}",
      "${data.terraform_remote_state.hub.cloudwatch_vpc_endpoint}"
    ]

    subnets = ["${data.terraform_remote_state.hub.internal_subnet_ids}"]
  }
}
