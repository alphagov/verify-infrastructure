locals {
  tools_account_ecr_url_prefix = "${var.tools_account_id}.dkr.ecr.eu-west-2.amazonaws.com/platform-deployer"

  ecs_agent_image_identifier = "${local.tools_account_ecr_url_prefix}-verify-ecs-agent@${var.ecs_agent_image_digest}"
  nginx_image_identifier     = "${local.tools_account_ecr_url_prefix}-verify-nginx-tls@${var.nginx_image_digest}"
}
