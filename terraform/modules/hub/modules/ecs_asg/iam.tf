resource "aws_kms_key" "cluster" {
  description = "${local.identifier}"
}

resource "aws_iam_role" "instance" {
  name = "${local.identifier}-instance"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF

  tags = {
    Deployment = var.deployment
  }
}

resource "aws_iam_instance_profile" "instance" {
  name = "${local.identifier}-instance"
  role = aws_iam_role.instance.name
}

resource "aws_iam_policy" "instance" {
  name        = "${local.identifier}-instance"
  description = "${local.identifier}-instance"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        "Resource": [
          "arn:aws:logs::${local.account_id}:${local.identifier}",
          "arn:aws:logs::${local.account_id}:${local.identifier}:*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DeleteParameter"
        ],
        "Resource": "arn:aws:ssm:eu-west-2:${local.account_id}:parameter/${local.identifier}/*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:Describe*",
          "kms:Decrypt"
        ],
        "Resource": "${aws_kms_key.cluster.arn}"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ssm:ListAssociations",
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetEncryptionConfiguration",
          "ecs:DiscoverPollEndpoint",
          "ecs:StartTelemetrySession",
          "ecs:Poll",
          "ecs:Submit*"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecs:RegisterContainerInstance",
          "ecs:DeregisterContainerInstance"
        ],
        "Resource": [
          "arn:aws:ecs:eu-west-2:${local.account_id}:cluster/${local.identifier}"
        ]
      },
      {
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
          "arn:aws:ecr:eu-west-2:${var.tools_account_id}:repository/platform-deployer-verify-ecs-agent"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken"
        ],
        "Resource": "*"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "instance" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.instance.arn
}

resource "aws_iam_role_policy_attachment" "instance_additional" {
  count      = length(var.additional_instance_role_policy_arns)
  role       = aws_iam_role.instance.name
  policy_arn = element(var.additional_instance_role_policy_arns, count.index)
}

resource "aws_iam_role_policy_attachment" "instance_ecs_service_role" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
