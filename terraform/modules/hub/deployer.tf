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
          "AWS": [
            "arn:aws:iam::047969882937:role/cd-verify-concourse-worker"
          ]
        },
        "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "deployer_administrator_access" {
  role       = aws_iam_role.deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy" "deployer_deny_release_address" {
  role       = aws_iam_role.deployer.name
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "ec2:ReleaseAddress",
        "Resource": "*",
        "Effect": "Deny"
      }
    ]
  }
  EOF
}
