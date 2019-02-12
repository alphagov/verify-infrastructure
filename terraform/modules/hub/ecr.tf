locals {
  tools_account_ecr_url_prefix = "${var.tools_account_id}.dkr.ecr.eu-west-2.amazonaws.com/platform-deployer"

  ecs_agent_image_and_tag = "${local.tools_account_ecr_url_prefix}-verify-ecs-agent:latest"
  nginx_image_identifier  = "${local.tools_account_ecr_url_prefix}-verify-nginx-tls@${var.nginx_image_digest}"
}
