variable "domain" {
  description = "Domain on which the app is hosted"
  default     = "localhost:3000"
}

locals {
  service = "self-service"
}

resource "aws_sns_topic" "cognito_sns_topic" {
  name = "cognito-sns-topic"
}

resource "aws_sns_topic_policy" "cognito_sns_policy" {
  arn = aws_sns_topic.cognito_sns_topic.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
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
      aws_sns_topic.cognito_sns_topic.arn,
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
  role = aws_iam_role.cognito_sns_role.id

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
    external_id    = "self-service-external"
    sns_caller_arn = aws_iam_role.cognito_sns_role.arn
  }

  software_token_mfa_configuration {
    enabled = true
  }

  username_attributes = [
    "email",
  ]

  admin_create_user_config {
    allow_admin_create_user_only = true
    invite_message_template {
      email_subject = "You have been invited to collaborate on the GOV.UK Verify Manage certificates service"
      email_message = <<-EOT
        <p>Dear {username}</p>
        
        <p>You have been invited to collaborate on the GOV.UK Verify Manage certificates service.</p>
        
        <p>Sign in at ${var.domain} using the following temporary password:</p>
        
        <p style="font-weight: bold;">{####}</p>
        
        <p>You will be asked to create a new password and set up multi-factor authentication using your preferred authentication app.</p>
        
        <p style="color: #d4351c">Please sign in within 24 hours, otherwise the temporary password will expire.</p>
        
        <p>If you miss this deadline, contact your admin to ask for another temporary password.</p>
        
        <p>Thanks</p>
        
        <p style="font-weight: bold;">The GOV.UK Verify team<br>
        <a href="https://www.verify.service.gov.uk/">https://www.verify.service.gov.uk/</a></p>
      EOT
      sms_message   = "Sign in at ${var.domain} using the following temporary password {####} and your email {username}."
    }
  }

  password_policy {
    minimum_length                   = 8
    temporary_password_validity_days = 1
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
    prevent_destroy = true
  }

}

resource "aws_cognito_user_pool_client" "client" {
  name                         = "${local.service}-user-pool-client"
  user_pool_id                 = aws_cognito_user_pool.user_pool.id
  explicit_auth_flows          = ["USER_PASSWORD_AUTH"]
  supported_identity_providers = ["COGNITO"]
  refresh_token_validity       = 1
}


output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

output "user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}
