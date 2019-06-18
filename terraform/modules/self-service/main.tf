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

data "aws_iam_policy_document" "config_metadata_bucket_policy" {
  statement {
    sid    = "DenyIncorrectEncryptionHeader"
    effect = "Deny"

    principals = {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = ["${aws_s3_bucket.config_metadata.arn}/*"]

    actions = ["s3:PutObject"]

    condition = {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }
}

resource "aws_s3_bucket_policy" "config_metadata_policy" {
  bucket = "${aws_s3_bucket.config_metadata.id}"
  policy = "${data.aws_iam_policy_document.config_metadata_bucket_policy.json}"
}

data "aws_iam_policy_document" "can_read_from_config_metadata_bucket" {
  statement {
    sid    = "BucketCanBeReadFrom"
    effect = "Allow"

    resources = [
      "arn:aws:s3:::${local.config_metadata_bucket}"
    ]

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]
  }

  statement {
    sid    = "ListAllBuckets"
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role" "output_bucket_reader" {
  name               = "${local.config_metadata_bucket}-reader"
  assume_role_policy = "${data.aws_iam_policy_document.can_read_from_config_metadata_bucket.json}"
}

resource "aws_iam_policy" "can_read_output_bucket" {
  name   = "can-read-${local.config_metadata_bucket}"
  policy = "${data.aws_iam_policy_document.can_read_from_config_metadata_bucket.json}"
}

resource "aws_iam_policy_attachment" "output_bucket_reader_can_read" {
  name = "${local.config_metadata_bucket}-can-read"

  roles = [
    "${aws_iam_role.output_bucket_reader.name}",
  ]

  policy_arn = "${aws_iam_policy.can_read_output_bucket.arn}"
}
