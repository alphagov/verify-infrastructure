resource "aws_iam_user" "deployer" {
  name = "${var.deployment}-deployer"
}
