module "saml_soap_proxy_ecs_asg" {
  source = "./modules/ecs_asg"

  ami_id              = data.aws_ami.ubuntu_bionic.id
  deployment          = var.deployment
  cluster             = "saml-soap-proxy"
  vpc_id              = aws_vpc.hub.id
  instance_subnets    = aws_subnet.internal.*.id
  number_of_instances = var.number_of_apps
  domain              = local.root_domain

  ecs_agent_image_identifier = local.ecs_agent_image_identifier
  tools_account_id           = var.tools_account_id

  additional_instance_security_group_ids = [
    aws_security_group.scraped_by_prometheus.id,
    aws_security_group.can_connect_to_container_vpc_endpoint.id,
  ]

  logit_api_key           = var.logit_api_key
  logit_elasticsearch_url = var.logit_elasticsearch_url
}

resource "aws_security_group_rule" "saml_soap_proxy_instance_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = module.saml_soap_proxy_ecs_asg.instance_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "saml_soap_proxy_instance_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = module.saml_soap_proxy_ecs_asg.instance_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}

locals {
  saml_soap_proxy_location_blocks = <<-LOCATIONS
  location = /prometheus/metrics {
    proxy_pass http://saml-soap-proxy:8081;
    proxy_set_header Host saml-soap-proxy.${local.root_domain};
  }
  location / {
    proxy_pass http://saml-soap-proxy:8080;
    proxy_set_header Host saml-soap-proxy.${local.root_domain};
  }
  LOCATIONS

  nginx_saml_soap_proxy_location_blocks_base64 = base64encode(local.saml_soap_proxy_location_blocks)
}

data "template_file" "saml_soap_proxy_task_def" {
  template = file("${path.module}/files/tasks/hub-saml-soap-proxy.json")

  vars = {
    image_identifier              = "${local.tools_account_ecr_url_prefix}-verify-saml-soap-proxy@${var.hub_saml_soap_proxy_image_digest}"
    nginx_image_identifier        = local.nginx_image_identifier
    domain                        = local.root_domain
    deployment                    = var.deployment
    location_blocks_base64        = local.nginx_saml_soap_proxy_location_blocks_base64
    region                        = data.aws_region.region.id
    account_id                    = data.aws_caller_identity.account.account_id
    event_emitter_api_gateway_url = var.event_emitter_api_gateway_url
    rp_truststore_enabled         = var.rp_truststore_enabled
  }
}

module "saml_soap_proxy" {
  source = "./modules/ecs_app"

  deployment                 = var.deployment
  cluster                    = "saml-soap-proxy"
  domain                     = local.root_domain
  vpc_id                     = aws_vpc.hub.id
  lb_subnets                 = aws_subnet.internal.*.id
  task_definition            = data.template_file.saml_soap_proxy_task_def.rendered
  container_name             = "nginx"
  container_port             = "8443"
  number_of_tasks            = var.number_of_apps
  health_check_path          = "/service-status"
  tools_account_id           = var.tools_account_id
  instance_security_group_id = module.saml_soap_proxy_ecs_asg.instance_sg_id
  certificate_arn            = var.wildcard_cert_arn
  image_name                 = "verify-saml-soap-proxy"
}

resource "aws_iam_policy" "saml_soap_proxy_parameter_execution" {
  name = "${var.deployment}-saml-soap-proxy-parameter-execution"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:kms:${data.aws_region.region.id}:${data.aws_caller_identity.account.account_id}:alias/${var.deployment}-saml-soap-proxy-key"
      ]
    }]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "saml_soap_proxy_parameter_execution" {
  role       = "${var.deployment}-saml-soap-proxy-execution"
  policy_arn = aws_iam_policy.saml_soap_proxy_parameter_execution.arn
}

module "saml_soap_proxy_can_connect_to_config" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_soap_proxy_ecs_asg.instance_sg_id
  destination_sg_id = module.config.lb_sg_id
}

module "saml_soap_proxy_can_connect_to_policy" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_soap_proxy_ecs_asg.instance_sg_id
  destination_sg_id = module.policy.lb_sg_id
}

module "saml_soap_proxy_can_connect_to_saml_engine" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_soap_proxy_ecs_asg.instance_sg_id
  destination_sg_id = module.saml_engine.lb_sg_id
}

module "saml_soap_proxy_can_connect_to_ingress_for_metadata" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_soap_proxy_ecs_asg.instance_sg_id
  destination_sg_id = aws_security_group.ingress.id
}
