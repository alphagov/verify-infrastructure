resource "aws_ecs_cluster" "cluster" {
  name = "${local.identifier}"
}

output "cluster_id" {
  value = "${aws_ecs_cluster.cluster.id}"
}

module "cluster_ecs_roles" {
  source = "../ecs_iam_role_pair"

  deployment       = "${var.deployment}"
  service_name     = "${var.cluster}"
  tools_account_id = "${var.tools_account_id}"
  image_name       = "${var.image_name}"
}

resource "aws_ecs_task_definition" "cluster" {
  family                = "${local.identifier}"
  container_definitions = "${var.task_definition}"
  execution_role_arn    = "${module.cluster_ecs_roles.execution_role_arn}"
  task_role_arn         = "${module.cluster_ecs_roles.task_role_arn}"
  network_mode          = "bridge"
}

output "task_role_name" {
  value = "${module.cluster_ecs_roles.task_role_name}"
}

resource "aws_ecs_service" "cluster" {
  name            = "${local.identifier}"
  cluster         = "${aws_ecs_cluster.cluster.id}"
  task_definition = "${aws_ecs_task_definition.cluster.arn}"

  desired_count                      = "${var.number_of_tasks}"
  deployment_minimum_healthy_percent = "${var.deployment_min_healthy_percent}"
  deployment_maximum_percent         = "${var.deployment_max_percent}"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.task.arn}"
    container_name   = "${var.container_name}"
    container_port   = "${var.container_port}"
  }
}
