data "aws_ami" "awslinux2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*"]
  }

  owners = ["amazon"]
}

data "aws_caller_identity" "account" {}

data "aws_region" "region" {}

locals {
  wildcard_cert_arn = "${var.wildcard_cert_arn}"
}
