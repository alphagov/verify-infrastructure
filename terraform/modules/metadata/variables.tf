variable "deployment" {
  description = "Name of the deployment; {staging|integration|prod}"
}

variable "tools_account_id" {
  description = "AWS account id of the tools account, where docker images will be pulled from"
}

variable "number_of_metadata_apps" {
  type    = number
  default = 2
}

variable "hub_metadata_image_digest" {}