module "policy_ecs_asg" {
  source = "modules/ecs_asg"

  ami_id           = "${data.aws_ami.ubuntu_bionic.id}"
  deployment       = "${var.deployment}"
  cluster          = "policy"
  vpc_id           = "${aws_vpc.hub.id}"
  instance_subnets = ["${aws_subnet.internal.*.id}"]

  number_of_instances = "${var.number_of_availability_zones}"
  domain              = "${local.root_domain}"

  additional_instance_security_group_ids = [
    "${aws_security_group.egress_via_proxy.id}",
    "${aws_security_group.scraped_by_prometheus.id}",
  ]

  logit_api_key           = "${var.logit_api_key}"
  logit_elasticsearch_url = "${var.logit_elasticsearch_url}"
}

locals {
  policy_location_blocks = <<-LOCATIONS
  location = /prometheus/metrics {
    proxy_pass http://policy:8081;
    proxy_set_header Host policy.${local.root_domain};
  }
  location / {
    proxy_pass http://policy:8080;
    proxy_set_header Host policy.${local.root_domain};
  }
  LOCATIONS

  nginx_policy_location_blocks_base64 = "${base64encode(local.policy_location_blocks)}"
}

data "template_file" "policy_task_def" {
  template = "${file("${path.module}/files/tasks/hub-policy.json")}"

  vars {
    image_and_tag          = "${local.tools_account_ecr_url_prefix}-verify-policy:latest"
    nginx_image_and_tag    = "${local.tools_account_ecr_url_prefix}-verify-nginx-tls:latest"
    domain                 = "${local.root_domain}"
    deployment             = "${var.deployment}"
    location_blocks_base64 = "${local.nginx_policy_location_blocks_base64}"
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
  container_name             = "nginx"
  container_port             = "8443"
  number_of_tasks            = 1
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

module "policy_can_connect_to_policy_redis" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.policy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${aws_security_group.policy_redis.id}"
  port              = 6379
}

module "policy_can_connect_to_ingress_for_metadata" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.policy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${aws_security_group.ingress.id}"
}
