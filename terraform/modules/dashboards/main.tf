data "template_file" "tickets_dashboard" {
  template = "${file("${path.module}/tickets_dashboard.json.tpl")}"

  vars = {
    deployment = "${var.deployment}"
    source     = "${var.data_source}"
  }
}
