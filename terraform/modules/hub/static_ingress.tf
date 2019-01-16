module "static_ingress_ecs_asg" {
  source = "modules/ecs_asg"

  ami_id              = "${data.aws_ami.ubuntu_bionic.id}"
  deployment          = "${var.deployment}"
  cluster             = "static-ingress"
  vpc_id              = "${aws_vpc.hub.id}"
  instance_subnets    = ["${aws_subnet.internal.*.id}"]
  number_of_instances = "${var.number_of_availability_zones}"
  use_egress_proxy    = true
  domain              = "${local.root_domain}"

  additional_instance_security_group_ids = [
    "${aws_security_group.egress_via_proxy.id}",
    "${aws_security_group.scraped_by_prometheus.id}",
  ]

  logit_api_key           = "${var.logit_api_key}"
  logit_elasticsearch_url = "${var.logit_elasticsearch_url}"
}

data "template_file" "static_ingress_task_def" {
  template = "${file("${path.module}/files/tasks/static-ingress.json")}"

  vars {
    image_and_tag = "${local.tools_account_ecr_url_prefix}-verify-static-ingress:latest"
    backends      = "${aws_lb.ingress.dns_name}"
  }
}

module "static_ingress_ecs_roles" {
  source = "modules/ecs_iam_role_pair"

  deployment       = "${var.deployment}"
  tools_account_id = "${var.tools_account_id}"
  service_name     = "static-ingress"
  image_name       = "verify-static-ingress"
}

resource "aws_ecs_task_definition" "static_ingress" {
  family                = "${var.deployment}-static-ingress"
  container_definitions = "${data.template_file.static_ingress_task_def.rendered}"
  execution_role_arn    = "${module.static_ingress_ecs_roles.execution_role_arn}"
}

resource "aws_ecs_cluster" "static-ingress" {
  name = "${var.deployment}-static-ingress"
}

resource "aws_security_group" "static_ingress" {
  name        = "${var.deployment}-static-ingress"
  description = "${var.deployment}-static-ingress"

  vpc_id = "${aws_vpc.hub.id}"
}

resource "aws_ecs_service" "static_ingress" {
  name            = "${var.deployment}-static-ingress"
  cluster         = "${aws_ecs_cluster.static-ingress.id}"
  task_definition = "${aws_ecs_task_definition.static_ingress.arn}"
  desired_count   = 1

  load_balancer {
    target_group_arn = "${aws_lb_target_group.static_ingress.arn}"
    container_name   = "static-ingress"
    container_port   = "4500"
  }
}

resource "aws_lb" "static_ingress" {
  name                             = "${var.deployment}-static-ingress"
  load_balancer_type               = "network"
  internal                         = false
  enable_cross_zone_load_balancing = true

  subnet_mapping {
    subnet_id     = "${element(aws_subnet.ingress.*.id, 0)}"
    allocation_id = "${element(aws_eip.ingress.*.id, 0)}"
  }

  subnet_mapping {
    subnet_id     = "${element(aws_subnet.ingress.*.id, 1)}"
    allocation_id = "${element(aws_eip.ingress.*.id, 1)}"
  }

  subnet_mapping {
    subnet_id     = "${element(aws_subnet.ingress.*.id, 2)}"
    allocation_id = "${element(aws_eip.ingress.*.id, 2)}"
  }
}

resource "aws_lb_target_group" "static_ingress" {
  name     = "${var.deployment}-static-ingress"
  port     = 4500
  protocol = "TCP"
  vpc_id   = "${aws_vpc.hub.id}"
}

resource "aws_lb_listener" "static_ingress" {
  load_balancer_arn = "${aws_lb.static_ingress.arn}"
  protocol          = "TCP"
  port              = 443

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.static_ingress.arn}"
  }
}
