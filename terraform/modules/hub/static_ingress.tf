module "static_ingress_ecs_asg" {
  source = "./modules/ecs_asg"

  ami_id              = data.aws_ami.ubuntu_bionic.id
  deployment          = var.deployment
  cluster             = "static-ingress"
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

resource "aws_security_group_rule" "static_ingress_instance_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = module.static_ingress_ecs_asg.instance_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "static_ingress_instance_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = module.static_ingress_ecs_asg.instance_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "static_ingress_ingress_from_internet_over_http" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = module.static_ingress_ecs_asg.instance_sg_id

  cidr_blocks = concat(
    var.publically_accessible_from_cidrs,
    formatlist("%s/32", aws_eip.egress.*.public_ip),
    aws_subnet.ingress.*.cidr_block,
  )

  # adding the egress IPs is a hack to let us access metadata through egress proxy
  # adding the ingress cidrs is so the network load balancer can healthcheck the boxes
}

resource "aws_security_group_rule" "static_ingress_ingress_from_internet_over_https" {
  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = module.static_ingress_ecs_asg.instance_sg_id

  cidr_blocks = concat(
    var.publically_accessible_from_cidrs,
    formatlist("%s/32", aws_eip.egress.*.public_ip),
    aws_subnet.ingress.*.cidr_block,
  )

  # adding the egress IPs is a hack to let us access metadata through egress proxy
  # adding the ingress cidrs is so the network load balancer can healthcheck the boxes
}

module "static_ingress_can_connect_to_ingress_http" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.static_ingress_ecs_asg.instance_sg_id
  destination_sg_id = aws_security_group.ingress.id

  port = 80
}

module "static_ingress_can_connect_to_ingress_https" {
  source = "./modules/microservice_connection"

  source_sg_id      = module.static_ingress_ecs_asg.instance_sg_id
  destination_sg_id = aws_security_group.ingress.id

  port = 443
}

locals {
  allocated_cpu_for_http     = 896
  allocated_cpu_for_https    = 1024
  allocated_memory_for_http  = 250
  allocated_memory_for_https = 3000
}

data "template_file" "static_ingress_http_task_def" {
  template = file("${path.module}/files/tasks/static-ingress.json")

  vars = {
    image_identifier = "${local.tools_account_ecr_url_prefix}-verify-static-ingress@${var.static_ingress_image_digest}"
    backend          = var.signin_domain
    bind_port        = 80
    backend_port     = 80
    allocated_cpu    = local.allocated_cpu_for_http
    allocated_memory = local.allocated_memory_for_http
  }
}

data "template_file" "static_ingress_https_task_def" {
  template = file("${path.module}/files/tasks/static-ingress.json")

  vars = {
    image_identifier = "${local.tools_account_ecr_url_prefix}-verify-static-ingress-tls@${var.static_ingress_tls_image_digest}"
    backend          = var.signin_domain
    bind_port        = 443
    backend_port     = 443
    allocated_cpu    = local.allocated_cpu_for_https
    allocated_memory = local.allocated_memory_for_https
  }
}

module "static_ingress_ecs_roles" {
  source = "./modules/ecs_iam_role_pair"

  deployment       = var.deployment
  tools_account_id = var.tools_account_id
  service_name     = "static-ingress"
  # This is used in an IAM Policy document, so wildcards are ok
  image_name = "verify-static-ingress*"
}

resource "aws_ecs_task_definition" "static_ingress_http" {
  family                = "${var.deployment}-static-ingress-http"
  container_definitions = data.template_file.static_ingress_http_task_def.rendered
  execution_role_arn    = module.static_ingress_ecs_roles.execution_role_arn
}

resource "aws_ecs_task_definition" "static_ingress_https" {
  family                = "${var.deployment}-static-ingress-https"
  container_definitions = data.template_file.static_ingress_https_task_def.rendered
  execution_role_arn    = module.static_ingress_ecs_roles.execution_role_arn
}

resource "aws_ecs_cluster" "static-ingress" {
  name = "${var.deployment}-static-ingress"
}

resource "aws_ecs_service" "static_ingress_http" {
  name            = "${var.deployment}-static-ingress-http"
  cluster         = aws_ecs_cluster.static-ingress.id
  task_definition = aws_ecs_task_definition.static_ingress_http.arn

  desired_count                      = var.number_of_apps
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.static_ingress_http.arn
    container_name   = "static-ingress"
    container_port   = "80"
  }
}

resource "aws_ecs_service" "static_ingress_https" {
  name            = "${var.deployment}-static-ingress-https"
  cluster         = aws_ecs_cluster.static-ingress.id
  task_definition = aws_ecs_task_definition.static_ingress_https.arn

  desired_count                      = var.number_of_apps
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 100

  load_balancer {
    target_group_arn = aws_lb_target_group.static_ingress_https.arn
    container_name   = "static-ingress"
    container_port   = "443"
  }
}

resource "aws_lb" "static_ingress" {
  name                             = "${var.deployment}-static-ingress"
  load_balancer_type               = "network"
  internal                         = false
  enable_cross_zone_load_balancing = true

  subnet_mapping {
    subnet_id     = element(aws_subnet.ingress.*.id, 0)
    allocation_id = element(aws_eip.ingress.*.id, 0)
  }

  subnet_mapping {
    subnet_id     = element(aws_subnet.ingress.*.id, 1)
    allocation_id = element(aws_eip.ingress.*.id, 1)
  }

  subnet_mapping {
    subnet_id     = element(aws_subnet.ingress.*.id, 2)
    allocation_id = element(aws_eip.ingress.*.id, 2)
  }
}

resource "aws_lb_target_group" "static_ingress_http" {
  name                 = "${var.deployment}-static-ingress-http"
  port                 = 80
  protocol             = "TCP"
  vpc_id               = aws_vpc.hub.id
  deregistration_delay = 30
}

resource "aws_lb_target_group" "static_ingress_https" {
  name                 = "${var.deployment}-static-ingress-https"
  port                 = 443
  protocol             = "TLS"
  vpc_id               = aws_vpc.hub.id
  deregistration_delay = 30
}

resource "aws_lb_listener" "static_ingress_http" {
  load_balancer_arn = aws_lb.static_ingress.arn
  protocol          = "TCP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.static_ingress_http.arn
  }
}

resource "aws_lb_listener" "static_ingress_https" {
  load_balancer_arn = aws_lb.static_ingress.arn
  protocol          = "TLS"
  port              = 443
  certificate_arn   = var.wildcard_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.static_ingress_https.arn
  }
}
