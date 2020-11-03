locals {
  service = "self-service"
  config_metadata_buckets_arns = [
    aws_s3_bucket.config_metadata.arn,
    "${aws_s3_bucket.config_metadata.arn}/*"
  ]
}

data "aws_region" "region" {}

data "terraform_remote_state" "hub" {
  backend = "s3"

  config = {
    bucket = "govukverify-tfstate-${var.deployment}"
    key    = "hub.tfstate"
    region = data.aws_region.region.id
  }
}

module "cognito" {
  source = "./modules/cognito"
  domain = var.domain
}
