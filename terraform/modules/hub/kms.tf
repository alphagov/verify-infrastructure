data "aws_iam_policy_document" "hub_key" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${var.deployment}-saml-engine-execution",
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${var.deployment}-saml-engine-fargate-execution",
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

  policy = data.aws_iam_policy_document.hub_key.json
}

resource "aws_kms_alias" "hub_key" {
  name          = "alias/${var.deployment}-hub-key"
  target_key_id = aws_kms_key.hub_key.key_id
}

data "aws_iam_policy_document" "frontend_key" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${var.deployment}-frontend-execution",
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

resource "aws_kms_key" "frontend" {
  description = "Used for encrypting and decrypting frontend secrets keys"
  key_usage   = "ENCRYPT_DECRYPT"

  deletion_window_in_days = 7

  policy = data.aws_iam_policy_document.frontend_key.json
}

resource "aws_kms_alias" "frontend" {
  name          = "alias/${var.deployment}-frontend-key"
  target_key_id = "${aws_kms_key.frontend.key_id}"
}

data "aws_iam_policy_document" "policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${var.deployment}-policy-execution",
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

resource "aws_kms_key" "policy" {
  description = "Used for encrypting and decrypting policy secret parameters"
  key_usage   = "ENCRYPT_DECRYPT"

  deletion_window_in_days = 7

  policy = data.aws_iam_policy_document.policy.json
}

resource "aws_kms_alias" "policy" {
  name          = "alias/${var.deployment}-policy-key"
  target_key_id = aws_kms_key.policy.key_id
}

data "aws_iam_policy_document" "saml_proxy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${var.deployment}-saml-proxy-execution",
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${module.saml_proxy_fargate.execution_role_name}",
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

resource "aws_kms_key" "saml_proxy" {
  description = "Used for encrypting and decrypting saml-proxy secret parameters"
  key_usage   = "ENCRYPT_DECRYPT"

  deletion_window_in_days = 7

  policy = data.aws_iam_policy_document.saml_proxy.json
}

resource "aws_kms_alias" "saml_proxy" {
  name          = "alias/${var.deployment}-saml-proxy-key"
  target_key_id = "${aws_kms_key.saml_proxy.key_id}"
}

data "aws_iam_policy_document" "saml_soap_proxy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${var.deployment}-saml-soap-proxy-execution",
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

resource "aws_kms_key" "saml_soap_proxy" {
  description = "Used for encrypting and decrypting saml-soap-proxy secret parameters"
  key_usage   = "ENCRYPT_DECRYPT"

  deletion_window_in_days = 7

  policy = data.aws_iam_policy_document.saml_soap_proxy.json
}

resource "aws_kms_alias" "saml_soap_proxy" {
  name          = "alias/${var.deployment}-saml-soap-proxy-key"
  target_key_id = aws_kms_key.saml_soap_proxy.key_id
}
