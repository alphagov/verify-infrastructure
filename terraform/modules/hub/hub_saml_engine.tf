module "saml_engine_ecs_asg" {
  source = "./modules/ecs_asg"

  ami_id           = data.aws_ami.ubuntu_bionic.id
  deployment       = var.deployment
  cluster          = "saml-engine"
  vpc_id           = aws_vpc.hub.id
  instance_subnets = aws_subnet.internal.*.id

  use_egress_proxy    = true
  number_of_instances = var.number_of_apps
  domain              = local.root_domain

  ecs_agent_image_identifier = local.ecs_agent_image_identifier
  tools_account_id           = var.tools_account_id

  additional_instance_security_group_ids = [
    aws_security_group.egress_via_proxy.id,
    aws_security_group.scraped_by_prometheus.id,
    aws_security_group.can_connect_to_container_vpc_endpoint.id,
  ]

  logit_api_key           = var.logit_api_key
  logit_elasticsearch_url = var.logit_elasticsearch_url
}

locals {
  saml_engine_location_blocks = <<-LOCATIONS
  location = /prometheus/metrics {
    proxy_pass http://saml-engine:8081;
    proxy_set_header Host saml-engine.${local.root_domain};
  }
  location / {
    proxy_pass http://saml-engine:8080;
    proxy_set_header Host saml-engine.${local.root_domain};
  }
  LOCATIONS

  nginx_saml_engine_location_blocks_base64 = base64encode(local.saml_engine_location_blocks)
}

data "template_file" "saml_engine_task_def" {
  template = file("${path.module}/files/tasks/hub-saml-engine.json")

  vars = {
    account_id             = data.aws_caller_identity.account.account_id
    deployment             = var.deployment
    domain                 = local.root_domain
    image_identifier       = "${local.tools_account_ecr_url_prefix}-verify-saml-engine@${var.hub_saml_engine_image_digest}"
    nginx_image_identifier = local.nginx_image_identifier
    region                 = data.aws_region.region.id
    location_blocks_base64 = local.nginx_saml_engine_location_blocks_base64
    redis_host             = "rediss://${aws_elasticache_replication_group.saml_engine_replay_cache.primary_endpoint_address}:6379"
    splunk_url             = var.splunk_url
    rp_truststore_enabled  = var.rp_truststore_enabled
  }
}

module "saml_engine" {
  source = "./modules/ecs_app"

  deployment                 = var.deployment
  cluster                    = "saml-engine"
  domain                     = local.root_domain
  vpc_id                     = aws_vpc.hub.id
  lb_subnets                 = aws_subnet.internal.*.id
  task_definition            = data.template_file.saml_engine_task_def.rendered
  container_name             = "nginx"
  container_port             = "8443"
  number_of_tasks            = var.number_of_apps
  health_check_path          = "/service-status"
  tools_account_id           = var.tools_account_id
  image_name                 = "verify-saml-engine"
  instance_security_group_id = module.saml_engine_ecs_asg.instance_sg_id
  certificate_arn            = var.wildcard_cert_arn
}

module "saml_engine_can_connect_to_config" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_engine_ecs_asg.instance_sg_id
  destination_sg_id = module.config.lb_sg_id
}

module "saml_engine_can_connect_to_policy" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_engine_ecs_asg.instance_sg_id
  destination_sg_id = module.policy.lb_sg_id
}

module "saml_engine_can_connect_to_saml_soap_proxy" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_engine_ecs_asg.instance_sg_id
  destination_sg_id = module.saml_soap_proxy.lb_sg_id
}

resource "aws_iam_policy" "saml_engine_parameter_execution" {
  name = "${var.deployment}-saml-engine-parameter-execution"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:ssm:${data.aws_region.region.id}:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}-hub-signing-private-key",
        "arn:aws:ssm:${data.aws_region.region.id}:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}-primary-hub-encryption-private-key",
        "arn:aws:ssm:${data.aws_region.region.id}:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}-secondary-hub-encryption-private-key",
        "arn:aws:kms:${data.aws_region.region.id}:${data.aws_caller_identity.account.account_id}:alias/${var.deployment}-hub-key"
      ]
    }]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "saml_engine_parameter_execution" {
  role       = "${var.deployment}-saml-engine-execution"
  policy_arn = aws_iam_policy.saml_engine_parameter_execution.arn
}

module "saml_engine_can_connect_to_saml_engine_redis" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_engine_ecs_asg.instance_sg_id
  destination_sg_id = aws_security_group.saml_engine_redis.id
  port              = 6379
}

module "saml_engine_can_connect_to_ingress_for_metadata" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_engine_ecs_asg.instance_sg_id
  destination_sg_id = aws_security_group.ingress.id
}
