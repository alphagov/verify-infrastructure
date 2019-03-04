data "aws_ami" "ubuntu_bionic" {
  most_recent = true

  # canonical
  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

data "aws_caller_identity" "account" {}

data "aws_region" "region" {}

locals {
  egress_proxy_url               = "egress-proxy.${local.root_domain}:8080"
  egress_proxy_url_with_protocol = "http://${local.egress_proxy_url}"
}
