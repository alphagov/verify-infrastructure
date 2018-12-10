module "egress_proxy_ecs_asg" {
  source = "modules/ecs_asg"

  ami_id              = "${data.aws_ami.awslinux2.id}"
  deployment          = "${var.deployment}"
  cluster             = "egress-proxy"
  vpc_id              = "${aws_vpc.hub.id}"
  instance_subnets    = ["${aws_subnet.internal.*.id}"]
  number_of_instances = "${var.number_of_availability_zones}"
  use_egress_proxy    = false
  domain              = "${var.domain}"
}

# Egress proxy instance has to be able to access the internet directly (HTTP)
resource "aws_security_group_rule" "egress_proxy_instance_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = "${module.egress_proxy_ecs_asg.instance_sg_id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Egress proxy instance has to be able to access the internet directly (HTTPS)
resource "aws_security_group_rule" "egress_proxy_instance_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = "${module.egress_proxy_ecs_asg.instance_sg_id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

locals {
  egress_proxy_whitelist_list = [
    "amazonlinux\\.eu-west-2\\.amazonaws\\.com",                               # Yum
    "repo\\.eu-west-2\\.amazonaws\\.com",                                      # Yum
    "packages\\.eu-west-2\\.amazonaws\\.com",                                  # Yum
    "amazon-ssm-eu-west-2\\.s3\\.amazonaws\\.com",                             # Where the package is from
    "ec2messages\\.eu-west-2\\.amazonaws\\.com",                               # SSM agent
    "ssmmessages\\.eu-west-2\\.amazonaws\\.com",                               # SSM agent
    "ssm\\.eu-west-2\\.amazonaws\\.com",                                       # SSM agent
    "ecs[^.]*\\.eu-west-2\\.amazonaws\\.com",                                  # ECS agent
    "ecr\\.eu-west-2\\.amazonaws\\.com",                                       # ECR
    "prod-eu-west-2-starport-layer-bucket\\.s3\\.eu-west-2\\.amazonaws\\.com", # ECR s3 bucket
    "${var.tools_account_id}\\.dkr\\.ecr\\.eu-west-2\\.amazonaws\\.com",       # Tools ECR auth
    "registry-1\\.docker\\.io",                                                # Docker Hub
    "auth\\.docker\\.io",                                                      # Docker Hub
    "production\\.cloudflare\\.docker\\.com",                                  # Docker Hub
  ]

  egress_proxy_whitelist = "${join(" ", local.egress_proxy_whitelist_list)}"
}

data "template_file" "egress_proxy_task_def" {
  template = "${file("${path.module}/files/tasks/squid.json")}"

  vars {
    whitelist_base64 = "${base64encode(local.egress_proxy_whitelist)}"
  }
}

resource "aws_elb" "egress_proxy" {
  name            = "${var.deployment}-egress-proxy"
  internal        = true
  subnets         = ["${aws_subnet.internal.*.id}"]
  security_groups = ["${aws_security_group.egress_proxy_lb.id}"]

  listener {
    instance_port     = 8080
    instance_protocol = "tcp"
    lb_port           = 8080
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8080"
    interval            = 10
  }

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_security_group" "egress_proxy_lb" {
  name        = "${var.deployment}-egress-proxy-lb"
  description = "${var.deployment}-egress-proxy-lb"

  vpc_id = "${aws_vpc.hub.id}"
}

resource "aws_security_group_rule" "egress_proxy_instance_ingress_from_egress_proxy_lb_over_nonpriv_http" {
  type     = "ingress"
  protocol = "tcp"

  from_port = 8080
  to_port   = 8080

  security_group_id        = "${module.egress_proxy_ecs_asg.instance_sg_id}"
  source_security_group_id = "${aws_security_group.egress_proxy_lb.id}"
}

resource "aws_security_group_rule" "egress_proxy_lb_egress_to_egress_proxy_instance_over_nonpriv_http" {
  type     = "egress"
  protocol = "tcp"

  from_port = 8080
  to_port   = 8080

  # source is destination for egress rules
  source_security_group_id = "${module.egress_proxy_ecs_asg.instance_sg_id}"
  security_group_id        = "${aws_security_group.egress_proxy_lb.id}"
}

resource "aws_security_group_rule" "egress_proxy_lb_ingress_from_egress_via_proxy_over_nonpriv_http" {
  type     = "ingress"
  protocol = "tcp"

  from_port = 8080
  to_port   = 8080

  security_group_id        = "${aws_security_group.egress_proxy_lb.id}"
  source_security_group_id = "${aws_security_group.egress_via_proxy.id}"
}

resource "aws_ecs_cluster" "egress_proxy" {
  name = "${var.deployment}-egress-proxy"
}

module "egress_proxy_ecs_roles" {
  source = "modules/ecs_iam_role_pair"

  deployment       = "${var.deployment}"
  service_name     = "egress-proxy"
  tools_account_id = "${var.tools_account_id}"
  image_name       = "verify-squid"
}

resource "aws_ecs_task_definition" "egress_proxy" {
  family                = "${var.deployment}-egress-proxy"
  container_definitions = "${data.template_file.egress_proxy_task_def.rendered}"
  execution_role_arn    = "${module.egress_proxy_ecs_roles.execution_role_arn}"
}

resource "aws_ecs_service" "egress_proxy" {
  name            = "${var.deployment}-egress-proxy"
  cluster         = "${aws_ecs_cluster.egress_proxy.id}"
  task_definition = "${aws_ecs_task_definition.egress_proxy.arn}"
  desired_count   = 1

  load_balancer {
    elb_name       = "${aws_elb.egress_proxy.name}"
    container_name = "squid"
    container_port = "8080"
  }
}

resource "aws_route53_zone" "egress_proxy" {
  name = "egress-proxy.${var.domain}."

  vpc {
    vpc_id = "${aws_vpc.hub.id}"
  }

  tags {
    Deployment = "${var.deployment}"
  }
}

resource "aws_route53_record" "egress_proxy_lb" {
  zone_id = "${aws_route53_zone.egress_proxy.zone_id}"
  name    = "egress-proxy.${var.domain}."
  type    = "A"

  alias {
    name                   = "${aws_elb.egress_proxy.dns_name}"
    zone_id                = "${aws_elb.egress_proxy.zone_id}"
    evaluate_target_health = false
  }
}

module "egress_proxy_instance_can_connect_to_config" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.egress_proxy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.config.lb_sg_id}"
}

module "egress_proxy_instance_can_connect_to_policy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.egress_proxy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.policy.lb_sg_id}"
}

module "egress_proxy_instance_can_connect_to_saml_proxy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.egress_proxy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.saml_proxy.lb_sg_id}"
}

module "egress_proxy_instance_can_connect_to_saml_soap_proxy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.egress_proxy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.saml_soap_proxy.lb_sg_id}"
}

module "egress_proxy_instance_can_connect_to_saml_engine" {
  source = "modules/microservice_connection"

  source_sg_id      = "${module.egress_proxy_ecs_asg.instance_sg_id}"
  destination_sg_id = "${module.saml_engine.lb_sg_id}"
}
