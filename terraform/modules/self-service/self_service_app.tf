data "aws_iam_policy_document" "self_service_user_write_to_bucket" {
  statement {
    sid       = "AllowGetAndPutObject"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.config_metadata.arn}/*"]
    actions   = [
      "s3:GetO*",
      "s3:PutO*",
      "s3:DeleteO*",
      "s3:ListBucket",
    ]
  }
}

resource "aws_iam_policy" "self_service_user_write_to_bucket" {
  name   = "${local.service}-iam-policy"
  policy = "${data.aws_iam_policy_document.self_service_user_write_to_bucket.json}"
}

resource "aws_iam_user" "self_service_user" {
  name = "${local.service}-user"
}

resource "aws_iam_user_policy_attachment" "self_service_user_policy_attachment" {
  user       = "${aws_iam_user.self_service_user.name}"
  policy_arn = "${aws_iam_policy.self_service_user_write_to_bucket.arn}"
}
