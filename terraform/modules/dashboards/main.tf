data "template_file" "service_tickets_dashboard" {
  template = "${file("${path.module}/service_tickets_dashboard.json.tpl")}"

  vars = {
    deployment = "${var.deployment}"
    source     = "${var.data_source}"
  }
}

data "template_file" "infra_tickets_dashboard" {
  template = "${file("${path.module}/infra_tickets_dashboard.json.tpl")}"

  vars = {
    deployment = "${var.deployment}"
    source     = "${var.data_source}"
  }
}

data "template_file" "verify_frontend_dashboard" {
  template = "${file("${path.module}/verify_frontend_dashboard.json.tpl")}"

  vars = {
    deployment = "${var.deployment}"
    source     = "${var.data_source}"
  }
}
