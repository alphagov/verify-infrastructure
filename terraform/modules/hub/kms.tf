data "aws_iam_policy_document" "hub_key" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${var.deployment}-saml-engine-execution",
      ]
    }

    actions = [
      "kms:*",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_kms_key" "hub_key" {
  description = "Used for encrypting and decrypting hub private keys"
  key_usage   = "ENCRYPT_DECRYPT"

  deletion_window_in_days = 7

  policy = "${data.aws_iam_policy_document.hub_key.json}"
}

resource "aws_kms_alias" "hub_key" {
  name          = "alias/${var.deployment}-hub-key"
  target_key_id = "${aws_kms_key.hub_key.key_id}"
}
