locals {
  egress_proxy_url = "egress-proxy.${var.domain}:8080"

  egress_proxy_url_with_protocol = "${
    var.use_egress_proxy
    ? "http://${local.egress_proxy_url}"
    : ""
  }"

  ecs_egress_proxy_setting = "${
    var.use_egress_proxy
    ? "HTTP_PROXY=${local.egress_proxy_url}"
    : "NOT_USING_HTTP_PROXY=yes"
  }"
}

data "template_file" "cloud_init" {
  template = "${file("${path.module}/files/cloud-init.sh")}"

  vars {
    cluster                        = "${local.identifier}"
    egress_proxy_url_with_protocol = "${local.egress_proxy_url_with_protocol}"
    ecs_egress_proxy_setting       = "${local.ecs_egress_proxy_setting}"
  }
}

resource "aws_launch_configuration" "cluster" {
  name_prefix          = "${local.identifier}"
  image_id             = "${var.ami_id}"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.instance.name}"
  user_data            = "${data.template_file.cloud_init.rendered}"

  security_groups = [
    "${var.additional_instance_security_group_ids}",
    "${aws_security_group.instance.id}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "cluster" {
  name                 = "${local.identifier}"
  launch_configuration = "${aws_launch_configuration.cluster.name}"
  min_size             = "${var.number_of_instances}"
  max_size             = "${var.number_of_instances}"
  desired_capacity     = "${var.number_of_instances}"
  vpc_zone_identifier  = ["${var.instance_subnets}"]

  tag {
    key                 = "Deployment"
    value               = "${var.deployment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Name"
    value               = "${local.identifier}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
