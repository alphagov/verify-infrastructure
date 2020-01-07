variable "cluster" {}
variable "container_name" {}
variable "container_port" {}
variable "deployment" {}
variable "domain" {}
variable "task_definition" {}
variable "cpu" {}
variable "memory" {}
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

variable "deployment_min_healthy_percent" {
  default = 50
}

variable "deployment_max_percent" {
  default = 100
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
