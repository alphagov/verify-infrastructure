# An execution role is the role which ECS uses to schedule containers on our
# behalf. I.e. ECS may need access to some params in parameter store to start tasks with the correct environment variables. The containers running in a
# task use a different role than the execution role.

resource "aws_iam_role" "execution" {
  name = "${var.deployment}-${var.service_name}-execution"

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

output "execution_role_arn" {
  value = "${aws_iam_role.execution.arn}"
}

resource "aws_iam_policy" "execution" {
  name = "${var.deployment}-${var.service_name}-execution"

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
      "Resource": "arn:aws:ecr:eu-west-2:${var.tools_account_id}:repository/platform-deployer-${local.image_name}"
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
  role       = "${aws_iam_role.execution.name}"
  policy_arn = "${aws_iam_policy.execution.arn}"
}
