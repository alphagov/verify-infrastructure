variable "deployment" {}
variable "service_name" {}
variable "tools_account_id" {}

variable "image_name" {
  default = ""
}

locals {
  image_name = "${
    length(var.image_name) == 0
    ? var.service_name
    : var.image_name
  }"
}

data "aws_caller_identity" "account" {}

locals {
  account_id = "${data.aws_caller_identity.account.account_id}"
}
