resource "aws_ecs_cluster" "cluster" {
  name = "${local.identifier}"
}

resource "aws_ecs_task_definition" "cluster" {
  family                = "${local.identifier}"
  container_definitions = "${var.task_definition}"
  network_mode          = "awsvpc"
}

resource "aws_ecs_service" "cluster" {
  name            = "${local.identifier}"
  cluster         = "${aws_ecs_cluster.cluster.id}"
  task_definition = "${aws_ecs_task_definition.cluster.arn}"
  desired_count   = "${var.number_of_tasks}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.task.arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }

  network_configuration {
    subnets          = ["${var.task_subnets}"]
    security_groups  = [
      "${aws_security_group.task.id}",
      "${var.additional_task_security_group_ids}",
    ]
  }
}
