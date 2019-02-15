output "tickets_dashboard_rendered" {
  value = "${data.template_file.tickets_dashboard.rendered}"
}

output "pages_dashboard_rendered" {
  value = "${data.template_file.pages_dashboard.rendered}"
}
