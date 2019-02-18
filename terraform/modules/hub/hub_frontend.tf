# frontend
#
# needs to connect to:
#   - config
#   - saml proxy
#   - policy
#
# frontend applications are run on the ingress asg

resource "aws_security_group" "frontend_task" {
  name        = "${var.deployment}-frontend-task"
  description = "${var.deployment}-frontend-task"

  vpc_id = "${aws_vpc.hub.id}"
}

resource "aws_security_group_rule" "frontend_task_egress_to_internet_over_http" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 80
  to_port   = 80

  security_group_id = "${aws_security_group.frontend_task.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "frontend_task_egress_to_internet_over_https" {
  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443

  security_group_id = "${aws_security_group.frontend_task.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}

locals {
  location_blocks = <<-LOCATIONS
  location / {
    proxy_pass http://localhost:8080;
    proxy_set_header Host ${var.signin_domain};
  }
  LOCATIONS

  location_blocks_base64 = "${base64encode(local.location_blocks)}"
}

data "template_file" "frontend_task_def" {
  template = "${file("${path.module}/files/tasks/frontend.json")}"

  vars {
    account_id             = "${data.aws_caller_identity.account.account_id}"
    deployment             = "${var.deployment}"
    image_identifier       = "${local.tools_account_ecr_url_prefix}-verify-frontend@${var.hub_frontend_image_digest}"
    nginx_image_identifier = "${local.nginx_image_identifier}"
    domain                 = "${local.root_domain}"
    region                 = "${data.aws_region.region.id}"
    location_blocks_base64 = "${local.location_blocks_base64}"
    zendesk_username       = "${var.zendesk_username}"
    zendesk_url            = "${var.zendesk_url}"
    matomo_site_id         = "${var.matomo_site_id}"
    analytics_endpoint     = "${var.analytics_endpoint}"
  }
}

module "frontend_ecs_roles" {
  source = "modules/ecs_iam_role_pair"

  deployment       = "${var.deployment}"
  tools_account_id = "${var.tools_account_id}"
  service_name     = "frontend"
  image_name       = "verify-frontend"
}

resource "aws_ecs_task_definition" "frontend" {
  family                = "${var.deployment}-frontend"
  container_definitions = "${data.template_file.frontend_task_def.rendered}"
  network_mode          = "awsvpc"
  execution_role_arn    = "${module.frontend_ecs_roles.execution_role_arn}"
}

resource "aws_ecs_service" "frontend" {
  name            = "${var.deployment}-frontend"
  cluster         = "${aws_ecs_cluster.ingress.id}"
  task_definition = "${aws_ecs_task_definition.frontend.arn}"

  desired_count                      = "${var.number_of_apps}"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  load_balancer {
    target_group_arn = "${aws_lb_target_group.ingress_frontend.arn}"
    container_name   = "nginx"
    container_port   = "8443"
  }

  network_configuration {
    subnets = ["${aws_subnet.internal.*.id}"]

    security_groups = [
      "${aws_security_group.frontend_task.id}",
      "${aws_security_group.can_connect_to_container_vpc_endpoint.id}",
    ]
  }
}

module "frontend_can_connect_to_config" {
  source = "modules/microservice_connection"

  source_sg_id      = "${aws_security_group.frontend_task.id}"
  destination_sg_id = "${module.config.lb_sg_id}"
}

module "frontend_can_connect_to_policy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${aws_security_group.frontend_task.id}"
  destination_sg_id = "${module.policy.lb_sg_id}"
}

module "frontend_can_connect_to_saml_proxy" {
  source = "modules/microservice_connection"

  source_sg_id      = "${aws_security_group.frontend_task.id}"
  destination_sg_id = "${module.saml_proxy.lb_sg_id}"
}

resource "random_string" "frontend_secret_key_base" {
  length  = 64
  special = false
}

resource "aws_ssm_parameter" "frontend_secret_key_base" {
  name   = "/${var.deployment}/frontend/secret-key-base"
  type   = "SecureString"
  key_id = "${aws_kms_key.frontend.key_id}"
  value  = "${random_string.frontend_secret_key_base.result}"
}

resource "aws_iam_policy" "frontend_parameter_execution" {
  name = "${var.deployment}-frontend-parameter-execution"

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
        "arn:aws:ssm:${data.aws_region.region.id}:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/frontend/*",
        "arn:aws:kms:${data.aws_region.region.id}:${data.aws_caller_identity.account.account_id}:alias/${var.deployment}-frontend"
      ]
    }]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "frontend_parameter_execution" {
  role       = "${var.deployment}-frontend-execution"
  policy_arn = "${aws_iam_policy.frontend_parameter_execution.arn}"
}
