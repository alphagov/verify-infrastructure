module "config_ecs_asg" {
  source = "./modules/ecs_asg"

  ami_id           = data.aws_ami.ubuntu_bionic.id
  deployment       = var.deployment
  cluster          = "config"
  vpc_id           = aws_vpc.hub.id
  instance_subnets = aws_subnet.internal.*.id

  number_of_instances = var.number_of_apps
  domain              = local.root_domain
  instance_type       = var.config_instance_type

  ecs_agent_image_identifier = local.ecs_agent_image_identifier
  tools_account_id           = var.tools_account_id

  additional_instance_security_group_ids = [
    aws_security_group.scraped_by_prometheus.id,
    aws_security_group.can_connect_to_container_vpc_endpoint.id,
  ]

  logit_api_key           = var.logit_api_key
  logit_elasticsearch_url = var.logit_elasticsearch_url
}

resource "aws_security_group_rule" "config_instance_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = module.config_ecs_asg.instance_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "config_instance_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = module.config_ecs_asg.instance_sg_id
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

  config_location_blocks_fargate = <<-LOCATIONS
  location = /prometheus/metrics {
    proxy_pass http://localhost:8081;
    proxy_set_header Host config.${local.root_domain};
  }
  location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host config.${local.root_domain};
  }
  LOCATIONS

  nginx_config_location_blocks_base64         = base64encode(local.config_location_blocks)
  nginx_config_location_blocks_fargate_base64 = base64encode(local.config_location_blocks_fargate)
  services_metadata_bucket                    = "govukverify-self-service-${var.deployment}-config-metadata"
  metadata_object_key                         = "verify_services_metadata.json"
}

data "template_file" "config_task_def" {
  template = file("${path.module}/files/tasks/hub-config.json")

  vars = {
    image_identifier         = "${local.tools_account_ecr_url_prefix}-verify-config@${var.hub_config_image_digest}"
    nginx_image_identifier   = local.nginx_image_identifier
    domain                   = local.root_domain
    deployment               = var.deployment
    truststore_password      = var.truststore_password
    location_blocks_base64   = local.nginx_config_location_blocks_base64
    region                   = data.aws_region.region.id
    account_id               = data.aws_caller_identity.account.account_id
    self_service_enabled     = var.self_service_enabled
    services_metadata_bucket = local.services_metadata_bucket
    metadata_object_key      = local.metadata_object_key
    memory_hard_limit        = var.config_memory_hard_limit
    jvm_options              = var.jvm_options
    log_level                = var.hub_config_log_level
  }
}

data "template_file" "config_task_def_fargate" {
  template = file("${path.module}/files/tasks/hub-config-fargate.json")

  vars = {
    image_identifier         = "${local.tools_account_ecr_url_prefix}-verify-config@${var.hub_config_image_digest}"
    nginx_image_identifier   = local.nginx_image_identifier
    domain                   = local.root_domain
    deployment               = var.deployment
    truststore_password      = var.truststore_password
    location_blocks_base64   = local.nginx_config_location_blocks_fargate_base64
    region                   = data.aws_region.region.id
    account_id               = data.aws_caller_identity.account.account_id
    self_service_enabled     = var.self_service_enabled
    services_metadata_bucket = local.services_metadata_bucket
    metadata_object_key      = local.metadata_object_key
    memory_hard_limit        = var.config_memory_hard_limit
    jvm_options              = var.jvm_options
  }
}

resource "aws_iam_policy" "can_read_config_metadata_bucket" {
  name   = "${var.deployment}-can-read-config-metadata-bucket"
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "BucketCanBeReadFrom",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetO*"
            ],
            "Resource": [
                "arn:aws:s3:::${local.services_metadata_bucket}",
                "arn:aws:s3:::${local.services_metadata_bucket}/*"
            ]
        }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "config_task_can_read_metadata_bucket" {
  role       = module.config.task_role_name
  policy_arn = aws_iam_policy.can_read_config_metadata_bucket.arn
}

module "config" {
  source = "./modules/ecs_app"

  deployment                 = var.deployment
  cluster                    = "config"
  domain                     = local.root_domain
  vpc_id                     = aws_vpc.hub.id
  lb_subnets                 = aws_subnet.internal.*.id
  task_definition            = data.template_file.config_task_def.rendered
  container_name             = "nginx"
  container_port             = "8443"
  number_of_tasks            = var.number_of_apps
  health_check_path          = "/service-status"
  tools_account_id           = var.tools_account_id
  image_name                 = "verify-config"
  instance_security_group_id = module.config_ecs_asg.instance_sg_id
  certificate_arn            = var.wildcard_cert_arn
}

resource "aws_iam_role_policy_attachment" "config-fargate_task_can_read_metadata_bucket" {
  role       = module.config-fargate.task_role_name
  policy_arn = aws_iam_policy.can_read_config_metadata_bucket.arn
}

module "config-fargate" {
  source = "./modules/ecs_fargate_app"

  deployment                 = var.deployment
  app                        = "config"
  domain                     = local.root_domain
  vpc_id                     = aws_vpc.hub.id
  lb_subnets                 = aws_subnet.internal.*.id
  task_definition            = data.template_file.config_task_def_fargate.rendered
  container_name             = "nginx"
  container_port             = "8443"
  number_of_tasks            = var.number_of_apps
  health_check_path          = "/service-status"
  tools_account_id           = var.tools_account_id
  image_name                 = "verify-config"
  certificate_arn            = var.wildcard_cert_arn
  ecs_cluster_id             = aws_ecs_cluster.fargate-ecs-cluster.id
  cpu                        = 2048
  # for a CPU of 2048 we need to set a RAM value between 4096 and 16384 (inclusive) that is a multiple of 1024.
  memory  = ceil(max(var.config_memory_hard_limit + 250, 4096) / 1024) * 1024
  subnets = aws_subnet.internal.*.id
  additional_task_security_group_ids = [
    aws_security_group.scraped_by_prometheus.id,
    aws_security_group.can_connect_to_container_vpc_endpoint.id,
  ]
}

resource "aws_security_group_rule" "config_task_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = module.config-fargate.task_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "config_task_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = module.config-fargate.task_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}
