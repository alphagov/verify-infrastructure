module "config_ecs_asg" {
  source = "modules/ecs_asg"

  ami_id           = "${data.aws_ami.ubuntu_bionic.id}"
  deployment       = "${var.deployment}"
  cluster          = "config"
  vpc_id           = "${aws_vpc.hub.id}"
  instance_subnets = ["${aws_subnet.internal.*.id}"]

  number_of_instances = "${var.number_of_apps}"
  domain              = "${local.root_domain}"

  ecs_agent_image_and_tag = "${local.ecs_agent_image_and_tag}"
  tools_account_id        = "${var.tools_account_id}"

  additional_instance_security_group_ids = [
    "${aws_security_group.scraped_by_prometheus.id}",
    "${aws_security_group.can_connect_to_container_vpc_endpoint.id}",
  ]

  logit_api_key           = "${var.logit_api_key}"
  logit_elasticsearch_url = "${var.logit_elasticsearch_url}"
}

resource "aws_security_group_rule" "config_instance_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = "${module.config_ecs_asg.instance_sg_id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "config_instance_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = "${module.config_ecs_asg.instance_sg_id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

locals {
  config_location_blocks = <<-LOCATIONS
  location = /prometheus/metrics {
    proxy_pass http://config:8081;
    proxy_set_header Host config.${local.root_domain};
  }
  location / {
    proxy_pass http://config:8080;
    proxy_set_header Host config.${local.root_domain};
  }
  LOCATIONS

  nginx_config_location_blocks_base64 = "${base64encode(local.config_location_blocks)}"
}

data "template_file" "config_task_def" {
  template = "${file("${path.module}/files/tasks/hub-config.json")}"

  vars {
    image_and_tag          = "${local.tools_account_ecr_url_prefix}-verify-config:${var.hub_config_image_tag}"
    nginx_image_and_tag    = "${local.tools_account_ecr_url_prefix}-verify-nginx-tls:latest"
    domain                 = "${local.root_domain}"
    deployment             = "${var.deployment}"
    truststore_password    = "${var.truststore_password}"
    location_blocks_base64 = "${local.nginx_config_location_blocks_base64}"
    region                 = "${data.aws_region.region.id}"
    account_id             = "${data.aws_caller_identity.account.account_id}"
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
  container_name             = "nginx"
  container_port             = "8443"
  number_of_tasks            = "${var.number_of_apps}"
  health_check_path          = "/service-status"
  tools_account_id           = "${var.tools_account_id}"
  image_name                 = "verify-config"
  instance_security_group_id = "${module.config_ecs_asg.instance_sg_id}"
  certificate_arn            = "${local.wildcard_cert_arn}"
}
