output "service_tickets_dashboard_rendered" {
  value = "${data.template_file.service_tickets_dashboard.rendered}"
}

output "verify_frontend_dashboard_rendered" {
  value = "${data.template_file.verify_frontend_dashboard.rendered}"
}
