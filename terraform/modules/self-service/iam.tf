resource "aws_iam_role_policy_attachment" "self_service_execution_write_to_logs_attachment" {
  role       = aws_iam_role.self_service_execution.name
  policy_arn = aws_iam_policy.can_write_to_logs.arn
}

resource "aws_iam_role" "self_service_execution" {
  name = "${local.service}-execution"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "self_service_scheduled_task_cloudwatch" {
  name               = "${local.service}-${var.deployment}-st-cloudwatch-role"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "events.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "self_service_scheduled_task_cloudwatch_policy" {
  name   = "${local.service}-${var.deployment}-st-cloudwatch-policy"
  role   = aws_iam_role.self_service_scheduled_task_cloudwatch.id
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecs:RunTask"
        ],
        "Resource": [
          "*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": "iam:PassRole",
        "Resource": [
          "${aws_iam_role.self_service_execution.arn}"
        ]
      }
    ]
  }
  EOF
}


resource "aws_iam_policy" "can_write_to_logs" {
  name = "${local.service}-can-write-to-logs"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:CreateLogGroup"
        ],
        "Resource": [
          "${aws_cloudwatch_log_group.self_service.arn}",
          "${aws_cloudwatch_log_group.self_service.arn}/*"
        ]
      }
    ]
  }
  EOF
}

data "aws_iam_policy_document" "kms_policy_document" {
  statement {
    sid    = "EncryptDecryptKMSParameters"
    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.account.account_id}:role/${local.service}-execution",
      ]
    }

    actions = ["kms:*"]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "self_service_secrets_policy" {
  name = "${local.service}-execution-secrets"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        "Resource": [
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/${var.deployment}/${local.service}/*"
        ]
      }, {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        "Resource": [
          "${aws_cloudwatch_log_group.self_service.arn}",
          "${aws_cloudwatch_log_group.self_service.arn}/*"
        ]
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "self_service_execution_secrets_policy_attachment" {
  role       = aws_iam_role.self_service_execution.name
  policy_arn = aws_iam_policy.self_service_secrets_policy.arn
}

resource "aws_iam_role" "self_service_task" {
  name = "${local.service}-task"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "self_service_cognito_policy" {
  name = "${local.service}-cognito-policy"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["*"],
        "Resource": [
          "arn:aws:cognito-idp:${data.aws_region.region.name}:${data.aws_caller_identity.account.account_id}:userpool/${module.cognito.user_pool_id}"
        ]
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "self_service_cognito_policy_attachment" {
  role       = aws_iam_role.self_service_task.name
  policy_arn = aws_iam_policy.self_service_cognito_policy.arn
}

resource "aws_iam_policy" "execution" {
  name = "${var.deployment}-${local.service}-execution"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage"
      ],
      "Resource": [
        "arn:aws:ecr:eu-west-2:753415395406:repository/platform-deployer-verify-${local.service}"
      ]
    }, {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    }]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "execution_execution" {
  role       = aws_iam_role.self_service_execution.name
  policy_arn = aws_iam_policy.execution.arn
}

data "aws_iam_policy_document" "access_config_metadata" {
  statement {
    sid       = "AllowGetAndPutObject"
    effect    = "Allow"
    resources = concat(local.config_metadata_buckets_arns, var.additional_buckets)

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
  }
}

resource "aws_iam_policy" "access_config_metadata" {
  name   = "${local.service}-access-config-metadata"
  policy = data.aws_iam_policy_document.access_config_metadata.json
}

resource "aws_iam_role_policy_attachment" "task_access_metadata_bucket_attachment" {
  role       = aws_iam_role.self_service_task.name
  policy_arn = aws_iam_policy.access_config_metadata.arn
}
