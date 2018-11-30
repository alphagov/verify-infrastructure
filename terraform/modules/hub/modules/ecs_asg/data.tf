data "aws_caller_identity" "account" {}

locals {
  account_id = "${data.aws_caller_identity.account.account_id}"
}
