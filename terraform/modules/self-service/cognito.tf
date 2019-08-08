resource "aws_cognito_user_pool" "user_pool" {
  name = "${local.service}-user-pool"

  username_attributes = [
    "email",
  ]

  admin_create_user_config {
    allow_admin_create_user_only = true
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
}

resource "aws_cognito_user_pool_client" "client" {
  name                         = "${local.service}-user-pool-client"
  user_pool_id                 = "${aws_cognito_user_pool.user_pool.id}"
  explicit_auth_flows          = ["USER_PASSWORD_AUTH"]
  supported_identity_providers = ["COGNITO"]
  refresh_token_validity       = 1
}
