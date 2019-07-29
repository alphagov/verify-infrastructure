resource "aws_kms_key" "self_service_key" {
  description = "Used for encrypting and decrypting self service private keys"
  key_usage   = "ENCRYPT_DECRYPT"

  deletion_window_in_days = 7

  policy = "${data.aws_iam_policy_document.kms_policy_document.json}"
}

resource "aws_kms_alias" "self_service_key" {
  name          = "alias/${var.deployment}-${local.service}-key"
  target_key_id = "${aws_kms_key.self_service_key.key_id}"
}
