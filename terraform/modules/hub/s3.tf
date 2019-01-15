resource "random_string" "deployment_config_bucket_name_suffix" {
  length  = 6
  special = false
  upper   = false
  number  = false
}

resource "aws_s3_bucket" "deployment_config" {
  bucket = "gds-${var.deployment}-config-${random_string.deployment_config_bucket_name_suffix.result}"

  acl = "private"

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
}
