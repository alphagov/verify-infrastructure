resource "aws_iam_role" "deployer" {
  name        = "${var.deployment}-deployer"
  description = "assumed by deployer concourse to deploy things"

  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "AWS": "arn:aws:iam::${var.tools_account_id}:role/concourse-worker"
        },
        "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_policy" "deployer_update_ecs" {
  name        = "${var.deployment}-deployer-update-ecs"
  description = "${var.deployment}-deployer-update-ecs"

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecs:List*",
          "ecs:Describe*",
          "ecs:UpdateService",
          "ecs:RegisterTaskDefinition"
        ],
        "Resource": [
          "*"
        ]
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "deployer_deployer_update_ecs" {
  role = "${aws_iam_role.deployer.name}"
  policy_arn = "${aws_iam_policy.deployer_update_ecs.arn}"
}
