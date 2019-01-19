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

variable "additional_execution_role_policy_arns" {
  default = []
}

variable "additional_task_role_policy_arns" {
  default = []
}

data "aws_caller_identity" "account" {}

locals {
  account_id = "${data.aws_caller_identity.account.account_id}"
}
