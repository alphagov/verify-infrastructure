data "aws_iam_policy_document" "self_service_user_write_to_bucket" {
  statement {
    sid       = "AllowGetAndPutObject"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.config_metadata.arn}/*"]

    actions = [
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

resource "aws_iam_role_policy_attachment" "self_service_execution_write_to_logs_attachment" {
  role       = "${aws_iam_role.self_service_execution.name}"
  policy_arn = "${aws_iam_policy.can_write_to_logs.arn}"
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
          "arn:aws:ssm:eu-west-2:${data.aws_caller_identity.account.account_id}:parameter/self-service/*"
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
  role       = "${aws_iam_role.self_service_execution.name}"
  policy_arn = "${aws_iam_policy.self_service_secrets_policy.arn}"
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
  role       = "${aws_iam_role.self_service_execution.name}"
  policy_arn = "${aws_iam_policy.execution.arn}"
}
