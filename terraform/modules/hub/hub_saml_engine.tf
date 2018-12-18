module "saml_engine_ecs_asg" {
  source = "modules/ecs_asg"

  ami_id           = "${data.aws_ami.awslinux2.id}"
  deployment       = "${var.deployment}"
  cluster          = "saml-engine"
  vpc_id           = "${aws_vpc.hub.id}"
  instance_subnets = ["${aws_subnet.internal.*.id}"]

  number_of_instances = "${var.number_of_availability_zones}"
  domain              = "${var.domain}"

  additional_instance_security_group_ids = [
    "${aws_security_group.egress_via_proxy.id}",
  ]
}

data "template_file" "saml_engine_task_def" {
  template = "${file("${path.module}/files/tasks/hub-saml-engine.json")}"

  vars {
    image_and_tag = "${local.tools_account_ecr_url_prefix}-verify-saml-engine:latest"
    domain        = "${var.domain}"
    deployment    = "${var.deployment}"
  }
}

module "saml_engine" {
  source = "modules/ecs_app"

  deployment            = "${var.deployment}"
  cluster               = "saml-engine"
  domain                = "${var.domain}"
  vpc_id                = "${aws_vpc.hub.id}"
  lb_subnets            = ["${aws_subnet.internal.*.id}"]
  task_definition       = "${data.template_file.saml_engine_task_def.rendered}"
  container_name        = "saml-engine"
  container_port        = "8080"
  number_of_tasks       = 1
  health_check_protocol = "HTTP"
  tools_account_id      = "${var.tools_account_id}"
  image_name                 = "verify-saml-engine"
  instance_security_group_id = "${module.saml_engine_ecs_asg.instance_sg_id}"
  certificate_arn            = "${data.aws_acm_certificate.wildcard.arn}"
}

module "saml_engine_can_connect_to_config" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.saml_engine_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.config.lb_sg_id}"
}

module "saml_engine_can_connect_to_policy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.saml_engine_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.policy.lb_sg_id}"
}

module "saml_engine_can_connect_to_saml_soap_proxy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.saml_engine_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.saml_soap_proxy.lb_sg_id}"
}
