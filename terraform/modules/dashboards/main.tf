data "template_file" "tickets_dashboard" {
  template = "${file("${path.module}/tickets_dashboard.json.tpl")}"
  vars = {
    deployment = "${var.deployment}"
    source     = "${var.data_source}"
  }
}

data "template_file" "pages_dashboard" {
  template = "${file("${path.module}/pages_dashboard.json.tpl")}"
  vars = {
    source     = "${var.data_source}"
  }
}

