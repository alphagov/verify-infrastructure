resource "aws_s3_bucket" "config_metadata" {
  bucket = "govukverify-${local.service}-${var.deployment}-config-metadata"
  region = data.aws_region.region.id

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

  tags = {
    Environment = var.deployment
    Service     = local.service
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "config_metadata_bucket_policy" {
  statement {
    sid    = "DenyIncorrectEncryptionHeader"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.config_metadata.arn}/*"]

    actions = ["s3:PutObject"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }
}

resource "aws_s3_bucket_policy" "config_metadata_policy" {
  bucket = aws_s3_bucket.config_metadata.id
  policy = data.aws_iam_policy_document.config_metadata_bucket_policy.json
}
