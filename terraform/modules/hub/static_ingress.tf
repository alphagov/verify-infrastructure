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

  logit_api_key           = "${var.logit_api_key}"
  logit_elasticsearch_url = "${var.logit_elasticsearch_url}"
}

data "template_file" "static_ingress_task_def" {
  template = "${file("${path.module}/files/tasks/static-ingress.json")}"

  vars {
    image_and_tag = "${local.tools_account_ecr_url_prefix}-verify-static-ingress:latest"
    deployment    = "${var.deployment}"
  }
}

module "static-ingress" {
  source = "modules/ecs_app"

  deployment                 = "${var.deployment}"
  cluster                    = "static-ingress"
  domain                     = "${local.root_domain}"
  vpc_id                     = "${aws_vpc.hub.id}"
  lb_subnets                 = ["${aws_subnet.internal.*.id}"]
  task_definition            = "${data.template_file.config_task_def.rendered}"
  container_name             = "nginx"
  container_port             = "8443"
  number_of_tasks            = 1
  health_check_path          = "/service-status"
  tools_account_id           = "${var.tools_account_id}"
  image_name                 = "verify-config"
  instance_security_group_id = "${module.config_ecs_asg.instance_sg_id}"
  certificate_arn            = "${local.wildcard_cert_arn}"
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
