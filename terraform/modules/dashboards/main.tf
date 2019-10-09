data "template_file" "service_tickets_dashboard" {
  template = file("${path.module}/service_tickets_dashboard.json.tpl")

  vars = {
    deployment = "${var.deployment}"
    source     = "${var.data_source}"
  }
}
