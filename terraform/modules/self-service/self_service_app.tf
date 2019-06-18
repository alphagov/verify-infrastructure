locals {
   service     = "govukverify-self-service"
   aws_region  = "eu-west-2"
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

resource "aws_iam_policy" "self_service_iam_policy" {
  name = "self-service-iam-policy"
  policy = "${data.aws_iam_policy_document.config_metadata_bucket_policy.json}"
}

resource "aws_s3_bucket_policy" "config_metadata_policy" {
  bucket = "${aws_s3_bucket.config_metadata.id}"
  policy = "${data.aws_iam_policy_document.config_metadata_bucket_policy.json}"
}

resource "aws_iam_user" "self-service-user"{
  name = "${local.service}-user"
}
