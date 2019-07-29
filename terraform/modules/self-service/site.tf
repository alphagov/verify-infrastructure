locals {
  service = "self-service"
}

data "aws_region" "region" {}

data "terraform_remote_state" "hub" {
  backend = "s3"

  config {
    bucket = "govukverify-tfstate-${var.deployment}"
    key    = "hub.tfstate"
    region = "${data.aws_region.region.id}"
  }
}

