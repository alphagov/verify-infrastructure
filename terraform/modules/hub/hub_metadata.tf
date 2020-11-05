# The metadata task and service are now defined in the metadata module - ../metadata

resource "aws_security_group" "metadata_task" {
  name        = "${var.deployment}-metadata-task"
  description = "${var.deployment}-metadata-task"

  vpc_id = aws_vpc.hub.id
}

module "metadata_ecs_roles" {
  source = "./modules/ecs_iam_role_pair"

  deployment       = var.deployment
  service_name     = "metadata"
  tools_account_id = var.tools_account_id
  image_name       = "verify-metadata"
}
