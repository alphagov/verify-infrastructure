module "policy_ecs_asg" {
  source = "modules/ecs_asg"

  ami_id           = "${data.aws_ami.awslinux2.id}"
  deployment       = "${var.deployment}"
  cluster          = "policy"
  vpc_id           = "${aws_vpc.hub.id}"
  instance_subnets = ["${aws_subnet.internal.*.id}"]

  number_of_instances = "${var.number_of_availability_zones}"
  domain              = "${local.root_domain}"

  additional_instance_security_group_ids = [
    "${aws_security_group.egress_via_proxy.id}",
  ]
}

data "template_file" "policy_task_def" {
  template = "${file("${path.module}/files/tasks/hub-policy.json")}"

  vars {
    image_and_tag = "${local.tools_account_ecr_url_prefix}-verify-policy:latest"
    domain        = "${local.root_domain}"
    deployment    = "${var.deployment}"
  }
}

module "policy" {
  source = "modules/ecs_app"

  deployment                 = "${var.deployment}"
  cluster                    = "policy"
  domain                     = "${local.root_domain}"
  vpc_id                     = "${aws_vpc.hub.id}"
  lb_subnets                 = ["${aws_subnet.internal.*.id}"]
  task_definition            = "${data.template_file.policy_task_def.rendered}"
  container_name             = "policy"
  container_port             = "8080"
  number_of_tasks            = 1
  health_check_protocol      = "HTTP"
  health_check_path          = "/service-status"
  tools_account_id           = "${var.tools_account_id}"
  image_name                 = "verify-policy"
  instance_security_group_id = "${module.policy_ecs_asg.instance_sg_id}"
  certificate_arn            = "${local.wildcard_cert_arn}"
}


module "policy_can_connect_to_config" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.policy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.config.lb_sg_id}"
}

module "policy_can_connect_to_saml_engine" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.policy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.saml_engine.lb_sg_id}"
}

module "policy_can_connect_to_saml_proxy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.policy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.saml_proxy.lb_sg_id}"
}

module "policy_can_connect_to_saml_soap_proxy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.policy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.saml_soap_proxy.lb_sg_id}"
}

module "policy_can_connect_to_event_sink" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.policy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.event_sink.lb_sg_id}"
}
