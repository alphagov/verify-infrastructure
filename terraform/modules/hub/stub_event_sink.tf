module "event_sink_ecs_asg" {
  source = "modules/ecs_asg"

  ami_id              = "${data.aws_ami.ubuntu_bionic.id}"
  deployment          = "${var.deployment}"
  cluster             = "event-sink"
  vpc_id              = "${aws_vpc.hub.id}"
  instance_subnets    = ["${aws_subnet.internal.*.id}"]
  number_of_instances = "${var.number_of_availability_zones}"
  domain              = "${local.root_domain}"

  additional_instance_security_group_ids = [
    "${aws_security_group.egress_via_proxy.id}",
  ]
}

data "template_file" "event_sink_task_def" {
  template = "${file("${path.module}/files/tasks/stub.json")}"
}

module "event_sink" {
  source = "modules/ecs_app"

  deployment                 = "${var.deployment}"
  cluster                    = "event-sink"
  domain                     = "${local.root_domain}"
  vpc_id                     = "${aws_vpc.hub.id}"
  lb_subnets                 = ["${aws_subnet.internal.*.id}"]
  task_definition            = "${data.template_file.event_sink_task_def.rendered}"
  container_name             = "stub"
  container_port             = "8080"
  number_of_tasks            = 1
  health_check_protocol      = "HTTP"
  tools_account_id           = "${var.tools_account_id}"
  instance_security_group_id = "${module.event_sink_ecs_asg.instance_sg_id}"
  certificate_arn            = "${local.wildcard_cert_arn}"
}
