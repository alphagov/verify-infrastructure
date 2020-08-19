resource "aws_security_group_rule" "saml_proxy_fargate_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = module.saml_proxy_fargate.task_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "saml_proxy_fargate_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = module.saml_proxy_fargate.task_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}

locals {
  saml_proxy_fargate_location_blocks = <<-LOCATIONS
  location = /prometheus/metrics {
    proxy_pass http://localhost:8081;
    proxy_set_header Host saml-proxy.${local.root_domain};
  }
  location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host saml-proxy.${local.root_domain};
  }
  LOCATIONS
}

module "saml_proxy_fargate" {
  source = "./modules/ecs_fargate_app"

  deployment = var.deployment
  app        = "saml-proxy"
  domain     = local.root_domain
  vpc_id     = aws_vpc.hub.id
  lb_subnets = aws_subnet.internal.*.id
  task_definition = templatefile("${path.module}/files/tasks/hub-saml-proxy.json",
    {
      image_identifier                 = "${local.tools_account_ecr_url_prefix}-verify-saml-proxy@${var.hub_saml_proxy_image_digest}"
      nginx_image_identifier           = local.nginx_image_identifier
      domain                           = local.root_domain
      deployment                       = var.deployment
      location_blocks_base64           = base64encode(local.saml_proxy_fargate_location_blocks)
      region                           = data.aws_region.region.id
      account_id                       = data.aws_caller_identity.account.account_id
      event_emitter_api_gateway_url    = var.event_emitter_api_gateway_url
      rp_truststore_enabled            = var.rp_truststore_enabled
      certificates_config_cache_expiry = var.certificates_config_cache_expiry
      jvm_options                      = var.jvm_options
      log_level                        = var.hub_saml_proxy_log_level
  })
  container_name    = "nginx"
  container_port    = "8443"
  number_of_tasks   = var.number_of_apps
  health_check_path = "/service-status"
  tools_account_id  = var.tools_account_id
  image_name        = "verify-saml-proxy"
  certificate_arn   = var.wildcard_cert_arn
  ecs_cluster_id    = aws_ecs_cluster.fargate-ecs-cluster.id
  cpu               = 2048
  # for a CPU of 2048 we need to set a RAM value between 4096 and 16384 (inclusive) that is a multiple of 1024.
  memory  = 4096
  subnets = aws_subnet.internal.*.id
  additional_task_security_group_ids = [
    aws_security_group.can_connect_to_container_vpc_endpoint.id,
    aws_security_group.hub_fargate_microservice.id,
  ]
  service_discovery_namespace_id = aws_service_discovery_private_dns_namespace.hub_apps.id
}

resource "aws_iam_policy" "saml_proxy_parameter_execution" {
  name = "${var.deployment}-saml-proxy-parameter-execution"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "ssm:GetParameter",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:kms:${data.aws_region.region.id}:${data.aws_caller_identity.account.account_id}:alias/${var.deployment}-saml-proxy-key",
        "arn:aws:ssm:${data.aws_region.region.id}:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/saml-proxy/*"
      ]
    }]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "saml_proxy_fargate_parameter_execution" {
  role       = module.saml_proxy_fargate.execution_role_name
  policy_arn = aws_iam_policy.saml_proxy_parameter_execution.arn
}

module "saml_proxy_fargate_can_connect_to_config_fargate_v2" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_proxy_fargate.task_sg_id
  destination_sg_id = module.config_fargate_v2.lb_sg_id
}

module "saml_proxy_fargate_can_connect_to_policy_fargate" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_proxy_fargate.task_sg_id
  destination_sg_id = module.policy_fargate.lb_sg_id
}

module "saml_proxy_fargate_can_connect_to_ingress_for_metadata" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.saml_proxy_fargate.task_sg_id
  destination_sg_id = aws_security_group.ingress.id
}
