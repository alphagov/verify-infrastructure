variable "ami_id" {}
variable "deployment" {}
variable "cluster" {}
variable "vpc_id" {}
variable "domain" {}

variable "instance_subnets" {
  type = "list"
}

locals {
  identifier = "${var.deployment}-${var.cluster}"
}

variable "number_of_instances" {
  default = 2
}

variable "additional_instance_security_group_ids" {
  default = []
}

variable "additional_instance_role_policy_arns" {
  default = []
}

variable "instance_type" {
  default = "t3.medium"
}

variable "use_egress_proxy" {
  default = true
}
