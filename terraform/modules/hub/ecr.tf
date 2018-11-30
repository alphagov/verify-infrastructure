# Apps

resource "aws_ecr_repository" "frontend" {
  name = "${var.deployment}-frontend"
}

resource "aws_ecr_repository" "config" {
  name = "${var.deployment}-config"
}

resource "aws_ecr_repository" "policy" {
  name = "${var.deployment}-policy"
}

resource "aws_ecr_repository" "saml_engine" {
  name = "${var.deployment}-saml-engine"
}

resource "aws_ecr_repository" "saml_proxy" {
  name = "${var.deployment}-saml-proxy"
}

resource "aws_ecr_repository" "saml_soap_proxy" {
  name = "${var.deployment}-saml-soap-proxy"
}

# Management

resource "aws_ecr_repository" "squid" {
  name = "${var.deployment}-squid"
}

resource "aws_ecr_repository" "sentry" {
  name = "${var.deployment}-sentry"
}
