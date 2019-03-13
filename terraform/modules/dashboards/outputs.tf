output "service_tickets_dashboard_rendered" {
  value = "${data.template_file.service_tickets_dashboard.rendered}"
}

output "infra_tickets_dashboard_rendered" {
  value = "${data.template_file.infra_tickets_dashboard.rendered}"
}

output "pages_dashboard_rendered" {
  value = "${data.template_file.pages_dashboard.rendered}"
}
