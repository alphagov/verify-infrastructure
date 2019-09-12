locals {
  service = "self-service"
}

resource "aws_sns_topic" "cognito_sns_topic" {
  name = "cognito-sns-topic"
}

resource "aws_sns_topic_policy" "cognito_sns_policy" {
  arn = "${aws_sns_topic.cognito_sns_topic.arn}"

  policy = "${data.aws_iam_policy_document.sns_topic_policy.json}"
}

data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "cognito-sns-topic-policy"

  statement {
    actions = [
      "SNS:Publish"
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      "${aws_sns_topic.cognito_sns_topic.arn}",
    ]

    sid = "20190910-cognito-sns-policy"
  }
}

resource "aws_iam_role" "cognito_sns_role" {
  name               = "cognito-sns-role"
  path               = "/service-role/"
  assume_role_policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "cognito-idp.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole"
            ]
        }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "cognito_sns_role_policy" {
  name = "cognito-sns-role-policy"
  role = "${aws_iam_role.cognito_sns_role.id}"

  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "sns:publish"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_cognito_user_pool" "user_pool" {
  name = "${local.service}-user-pool"

  mfa_configuration = "ON"

  auto_verified_attributes = [
    "email"
  ]

  sms_configuration {
    external_id = "self-service-external"
    sns_caller_arn = "${aws_iam_role.cognito_sns_role.arn}"
  }

  username_attributes = [
    "email",
  ]

  admin_create_user_config {
    allow_admin_create_user_only = true
    # This is currently unsupported in terraform
    # and is manually adjusted in the AWS console.
    # Having it here makes sure we can ignore it.
    unused_account_validity_days = 1
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true

    string_attribute_constraints {
      min_length = 1
      max_length = 320
    }
  }

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    mutable             = true
    required            = false

    string_attribute_constraints {
      min_length = 1
      max_length = 16
    }
  }

  schema {
    name                = "family_name"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 512
    }
  }

  schema {
    name                = "given_name"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 512
    }
  }

  schema {
    name                = "roles"
    attribute_data_type = "String"
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 512
    }
  }

  lifecycle {
    ignore_changes = [
      admin_create_user_config["unused_account_validity_days"]
    ]

    prevent_destroy = false
  }

  provisioner "local-exec" {
    command = "aws cognito-idp set-user-pool-mfa-config --user-pool-id ${aws_cognito_user_pool.user_pool.id} --software-token-mfa-configuration Enabled=true --mfa-configuration ON"
  }

}

resource "aws_cognito_user_pool_client" "client" {
  name                         = "${local.service}-user-pool-client"
  user_pool_id                 = "${aws_cognito_user_pool.user_pool.id}"
  explicit_auth_flows          = ["USER_PASSWORD_AUTH"]
  supported_identity_providers = ["COGNITO"]
  refresh_token_validity       = 1
}


output "user_pool_client_id" {
  value = "${aws_cognito_user_pool_client.client.id}"
}

output "user_pool_id" {
  value = "${aws_cognito_user_pool.user_pool.id}"
}
