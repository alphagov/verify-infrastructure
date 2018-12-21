module "saml_proxy_ecs_asg" {
  source = "modules/ecs_asg"

  ami_id              = "${data.aws_ami.awslinux2.id}"
  deployment          = "${var.deployment}"
  cluster             = "saml-proxy"
  vpc_id              = "${aws_vpc.hub.id}"
  instance_subnets    = ["${aws_subnet.internal.*.id}"]
  number_of_instances = "${var.number_of_availability_zones}"
  domain              = "${local.root_domain}"

  additional_instance_security_group_ids = [
    "${aws_security_group.egress_via_proxy.id}",
  ]
}

data "template_file" "saml_proxy_task_def" {
  template = "${file("${path.module}/files/tasks/hub-saml-proxy.json")}"

  vars {
    image_and_tag = "${local.tools_account_ecr_url_prefix}-verify-saml-proxy:latest"
    domain        = "${local.root_domain}"
    deployment    = "${var.deployment}"
  }
}

module "saml_proxy" {
  source = "modules/ecs_app"

  deployment                 = "${var.deployment}"
  cluster                    = "saml-proxy"
  domain                     = "${local.root_domain}"
  vpc_id                     = "${aws_vpc.hub.id}"
  lb_subnets                 = ["${aws_subnet.internal.*.id}"]
  task_definition            = "${data.template_file.saml_proxy_task_def.rendered}"
  container_name             = "saml-proxy"
  container_port             = "8080"
  number_of_tasks            = 1
  health_check_protocol      = "HTTP"
  health_check_path          = "/service-status"
  tools_account_id           = "${var.tools_account_id}"
  instance_security_group_id = "${module.saml_proxy_ecs_asg.instance_sg_id}"
  certificate_arn            = "${local.wildcard_cert_arn}"
  image_name                 = "verify-saml-proxy"
}

module "saml_proxy_can_connect_to_config" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.saml_proxy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.config.lb_sg_id}"
}

module "saml_proxy_can_connect_to_policy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.saml_proxy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.policy.lb_sg_id}"
}

module "saml_proxy_can_connect_to_event_sink" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.saml_proxy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.event_sink.lb_sg_id}"
}
