locals {
   service     = "govukverify-self-service"
   aws_region  = "eu-west-2"
   config_metadata_bucket = "${local.service}-${var.deployment}-config-metadata"
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
