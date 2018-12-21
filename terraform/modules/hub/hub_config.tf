module "config_ecs_asg" {
  source = "modules/ecs_asg"

  ami_id           = "${data.aws_ami.awslinux2.id}"
  deployment       = "${var.deployment}"
  cluster          = "config"
  vpc_id           = "${aws_vpc.hub.id}"
  instance_subnets = ["${aws_subnet.internal.*.id}"]

  number_of_instances = "${var.number_of_availability_zones}"
  domain              = "${local.root_domain}"

  additional_instance_security_group_ids = [
    "${aws_security_group.egress_via_proxy.id}",
  ]
}

data "template_file" "config_task_def" {
  template = "${file("${path.module}/files/tasks/hub-config.json")}"

  vars {
    image_and_tag       = "${local.tools_account_ecr_url_prefix}-verify-config:latest"
    domain              = "${local.root_domain}"
    deployment          = "${var.deployment}"
    truststore_password = "${var.truststore_password}"
  }
}

module "config" {
  source = "modules/ecs_app"

  deployment                 = "${var.deployment}"
  cluster                    = "config"
  domain                     = "${local.root_domain}"
  vpc_id                     = "${aws_vpc.hub.id}"
  lb_subnets                 = ["${aws_subnet.internal.*.id}"]
  task_definition            = "${data.template_file.config_task_def.rendered}"
  container_name             = "config"
  container_port             = "8080"
  number_of_tasks            = 1
  health_check_protocol      = "HTTP"
  health_check_path          = "/service-status"
  tools_account_id           = "${var.tools_account_id}"
  image_name                 = "verify-config"
  instance_security_group_id = "${module.config_ecs_asg.instance_sg_id}"
  certificate_arn            = "${local.wildcard_cert_arn}"
}
