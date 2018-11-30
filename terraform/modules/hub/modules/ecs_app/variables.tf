variable "cluster" {}
variable "container_name" {}
variable "container_port" {}
variable "deployment" {}
variable "domain" {}
variable "task_definition" {}
variable "vpc_id" {}

variable "task_subnets" {
  type = "list"
}

locals {
  identifier = "${var.deployment}-${var.cluster}"
}

variable "number_of_tasks" {
  default = 2
}

variable "additional_task_security_group_ids" {
  default = []
}

variable "additional_task_iam_policy_arns" {
  default = []
}

variable "health_check_path" {
  default = "/"
}

variable "health_check_protocol" {
  default = "HTTPS"
}

variable "health_check_interval" {
  default = 10
}

variable "health_check_timeout" {
  default = 5
}

variable "health_check_http_codes" {
  default = "200"
}
