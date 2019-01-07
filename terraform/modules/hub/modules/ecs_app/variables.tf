variable "cluster" {}
variable "container_name" {}
variable "container_port" {}
variable "deployment" {}
variable "domain" {}
variable "task_definition" {}
variable "vpc_id" {}
variable "tools_account_id" {}
variable "instance_security_group_id" {}
variable "certificate_arn" {}

variable "image_name" {
  default = ""
}

variable "lb_subnets" {
  type = "list"
}

locals {
  identifier = "${var.deployment}-${var.cluster}"
}

variable "number_of_tasks" {
  default = 2
}

variable "additional_task_role_policy_arns" {
  default = []
}

variable "additional_execution_role_policy_arns" {
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

variable "aws_lb_target_group_port" {
  default = 80
}

variable "aws_lb_target_group_protocol" {
  default = "HTTP"
}