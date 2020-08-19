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

variable "instance_type" {}

variable "logit_api_key" {}
variable "logit_elasticsearch_url" {}
variable "ecs_agent_image_identifier" {}
variable "tools_account_id" {}
