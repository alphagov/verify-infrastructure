# verify-infrastructure

## Create a new dashboard

To create a new Grafana dashboard:

1. Create the dashboard via the Grafana GUI
2. Copy the JSON for the dashboard you created
3. Create a template file containing the JSON in `terraform/modules/dashboards`
   1. Set the datasource to be `"${source}"`
   2. Add the following tags: `"verify"` and `"${deployment}"`
4. Add the new dashboard to [`main.tf`](terraform/modules/dashboards/main.tf) and [`outputs.tf`](terraform/modules/dashboards/outputs.tf)
5. Edit the config (https://github.com/alphagov/verify-terraform) to pull in the new dashboard
