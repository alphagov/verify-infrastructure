module "saml_engine_ecs_asg" {
  source = "modules/ecs_asg"

  ami_id              = "${data.aws_ami.awslinux2.id}"
  deployment          = "${var.deployment}"
  cluster             = "saml-engine"
  vpc_id              = "${aws_vpc.hub.id}"
  instance_subnets    = ["${aws_subnet.internal.*.id}"]
  # number_of_instances = "${var.number_of_availability_zones}"
  number_of_instances = 0
  domain              = "${var.domain}"

  additional_instance_security_group_ids = [
    "${aws_security_group.egress_via_proxy.id}",
  ]
}
data "template_file" "saml_engine_task_def" {
  template = "${file("${path.module}/files/tasks/stub.json")}"

  vars {
    app = "saml_engine"
  }
}

module "saml_engine" {
  source = "modules/ecs_app"

  deployment            = "${var.deployment}"
  cluster               = "saml-engine"
  domain                = "${var.domain}"
  vpc_id                = "${aws_vpc.hub.id}"
  task_subnets               = ["${aws_subnet.internal.*.id}"]
  task_definition       = "${data.template_file.saml_engine_task_def.rendered}"
  container_name        = "stub"
  container_port        = "8080"
  number_of_tasks       = 1
  health_check_protocol = "HTTP"
  tools_account_id      = "${var.tools_account_id}"

  additional_task_security_group_ids = [
    "${aws_security_group.egress_via_proxy.id}"
  ]
}
