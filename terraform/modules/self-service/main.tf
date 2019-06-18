locals {
   service     = "govukverify-self-service"
   aws_region  = "eu-west-2"
   config_metadata_bucket = "${local.service}-${var.deployment}-config-metadata"
}

resource "aws_s3_bucket" "config_metadata" {
  bucket  = "${local.service}-${var.deployment}-config-metadata"
  region  = "${local.aws_region}"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  tags {
    Environment = "${var.deployment}"
    Service     = "${local.service}"
    ManagedBy   = "terraform"
  }
}
