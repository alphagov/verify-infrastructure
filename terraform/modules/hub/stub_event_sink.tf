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

  logit_api_key           = "${var.logit_api_key}"
  logit_elasticsearch_url = "${var.logit_elasticsearch_url}"
}

locals {
  event_sink_location_blocks = <<-LOCATIONS
  location / {
    return 200;
  }
  LOCATIONS

  nginx_event_sink_location_blocks_base64 = "${base64encode(local.event_sink_location_blocks)}"
}

data "template_file" "event_sink_task_def" {
  template = "${file("${path.module}/files/tasks/stub.json")}"

  vars {
    nginx_image_and_tag    = "${local.tools_account_ecr_url_prefix}-verify-nginx-tls:latest"
    location_blocks_base64 = "${local.nginx_event_sink_location_blocks_base64}"
  }
}

module "event_sink" {
  source = "modules/ecs_app"

  deployment                   = "${var.deployment}"
  cluster                      = "event-sink"
  domain                       = "${local.root_domain}"
  vpc_id                       = "${aws_vpc.hub.id}"
  lb_subnets                   = ["${aws_subnet.internal.*.id}"]
  task_definition              = "${data.template_file.event_sink_task_def.rendered}"
  container_name               = "nginx"
  container_port               = "8443"
  number_of_tasks              = 1
  aws_lb_target_group_port     = 8443
  aws_lb_target_group_protocol = "HTTPS"
  tools_account_id             = "${var.tools_account_id}"
  instance_security_group_id   = "${module.event_sink_ecs_asg.instance_sg_id}"
  certificate_arn              = "${local.wildcard_cert_arn}"
}
