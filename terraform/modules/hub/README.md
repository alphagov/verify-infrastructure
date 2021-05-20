## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| template | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| analytics_ecs_roles | ./modules/ecs_iam_role_pair |  |
| cloudwatch_exporter_ecs_roles | ./modules/ecs_iam_role_pair |  |
| config_fargate_v2 | ./modules/ecs_fargate_app |  |
| container_vpc_endpoint_sg_connection | ./modules/microservice_connection |  |
| egress_proxy_ecs_roles | ./modules/ecs_iam_role_pair |  |
| frontend_can_connect_to_config_fargate_v2 | ./modules/microservice_connection |  |
| frontend_can_connect_to_policy_fargate | ./modules/microservice_connection |  |
| frontend_can_connect_to_saml_proxy_fargate | ./modules/microservice_connection |  |
| frontend_ecs_roles | ./modules/ecs_iam_role_pair |  |
| ingress_can_connect_to_analytics_task | ./modules/microservice_connection |  |
| ingress_can_connect_to_frontend_task | ./modules/microservice_connection |  |
| ingress_can_connect_to_metadata_task | ./modules/microservice_connection |  |
| metadata_ecs_roles | ./modules/ecs_iam_role_pair |  |
| metadata_exporter_ecs_roles | ./modules/ecs_iam_role_pair |  |
| mgmt_lb_can_talk_to_prometheus | ./modules/microservice_connection |  |
| policy_fargate | ./modules/ecs_fargate_app |  |
| policy_fargate_can_connect_to_config_fargate_v2 | ./modules/microservice_connection |  |
| policy_fargate_can_connect_to_ingress_for_metadata | ./modules/microservice_connection |  |
| policy_fargate_can_connect_to_policy_redis | ./modules/microservice_connection |  |
| policy_fargate_can_connect_to_saml_engine_fargate | ./modules/microservice_connection |  |
| policy_fargate_can_connect_to_saml_proxy_fargate | ./modules/microservice_connection |  |
| policy_fargate_can_connect_to_saml_soap_proxy_fargate | ./modules/microservice_connection |  |
| prometheus_can_talk_to_cloudwatch_vpc_endpoint | ./modules/microservice_connection |  |
| prometheus_can_talk_to_frontend_task | ./modules/microservice_connection |  |
| prometheus_can_talk_to_hub_fargate_microservices | ./modules/microservice_connection |  |
| prometheus_can_talk_to_ingress_for_scraping_metadata | ./modules/microservice_connection |  |
| prometheus_can_talk_to_prometheus | ./modules/microservice_connection |  |
| prometheus_can_talk_to_prometheus_beat_exporter | ./modules/microservice_connection |  |
| prometheus_can_talk_to_prometheus_node_exporter | ./modules/microservice_connection |  |
| prometheus_ecs_roles | ./modules/ecs_iam_role_pair |  |
| saml_engine_fargate | ./modules/ecs_fargate_app |  |
| saml_engine_fargate_can_connect_to_config_fargate_v2 | ./modules/microservice_connection |  |
| saml_engine_fargate_can_connect_to_ingress_for_metadata | ./modules/microservice_connection |  |
| saml_engine_fargate_can_connect_to_policy_fargate | ./modules/microservice_connection |  |
| saml_engine_fargate_can_connect_to_saml_engine_redis | ./modules/microservice_connection |  |
| saml_engine_fargate_can_connect_to_saml_soap_proxy_fargate | ./modules/microservice_connection |  |
| saml_proxy_fargate | ./modules/ecs_fargate_app |  |
| saml_proxy_fargate_can_connect_to_config_fargate_v2 | ./modules/microservice_connection |  |
| saml_proxy_fargate_can_connect_to_ingress_for_metadata | ./modules/microservice_connection |  |
| saml_proxy_fargate_can_connect_to_policy_fargate | ./modules/microservice_connection |  |
| saml_soap_proxy_fargate | ./modules/ecs_fargate_app |  |
| saml_soap_proxy_fargate_can_connect_to_config_fargate_v2 | ./modules/microservice_connection |  |
| saml_soap_proxy_fargate_can_connect_to_ingress_for_metadata | ./modules/microservice_connection |  |
| saml_soap_proxy_fargate_can_connect_to_policy_fargate | ./modules/microservice_connection |  |
| saml_soap_proxy_fargate_can_connect_to_saml_engine_fargate | ./modules/microservice_connection |  |
| scraped_by_prometheus_beat_can_be_scraped_by_prometheus | ./modules/microservice_connection |  |
| scraped_by_prometheus_can_be_scraped_by_prometheus | ./modules/microservice_connection |  |
| static_ingress_ecs_roles | ./modules/ecs_iam_role_pair |  |
| static_ingress_fargate_can_connect_to_ingress_http | ./modules/microservice_connection |  |
| static_ingress_fargate_can_connect_to_ingress_https | ./modules/microservice_connection |  |

## Resources

| Name |
|------|
| [aws_acm_certificate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) |
| [aws_acm_certificate_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) |
| [aws_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) |
| [aws_availability_zones](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) |
| [aws_caller_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) |
| [aws_cloudwatch_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) |
| [aws_cloudwatch_log_subscription_filter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_subscription_filter) |
| [aws_ebs_volume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) |
| [aws_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) |
| [aws_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) |
| [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) |
| [aws_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) |
| [aws_elasticache_parameter_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_parameter_group) |
| [aws_elasticache_replication_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_replication_group) |
| [aws_elasticache_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) |
| [aws_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) |
| [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_iam_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) |
| [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |
| [aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) |
| [aws_internet_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) |
| [aws_kms_alias](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) |
| [aws_kms_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) |
| [aws_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) |
| [aws_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) |
| [aws_lb_listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) |
| [aws_lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) |
| [aws_lb_target_group_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) |
| [aws_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) |
| [aws_region](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) |
| [aws_route](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) |
| [aws_route53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) |
| [aws_route53_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) |
| [aws_route_table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) |
| [aws_route_table_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |
| [aws_security_group_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) |
| [aws_service_discovery_private_dns_namespace](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_private_dns_namespace) |
| [aws_service_discovery_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) |
| [aws_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) |
| [aws_volume_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/volume_attachment) |
| [aws_vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) |
| [aws_vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) |
| [template_file](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| analytics\_endpoint | Analytics endpoint | `any` | n/a | yes |
| cloudwatch\_exporter\_image\_digest | n/a | `any` | n/a | yes |
| cls\_destination\_arn | ARN of the CSLS destination to send logs to | `any` | n/a | yes |
| deployment | Name of the deployment; {joint,staging,prod,integration} | `any` | n/a | yes |
| ecs\_agent\_image\_digest | n/a | `any` | n/a | yes |
| event\_emitter\_api\_gateway\_url | URL for Event Emitter API Gateway | `any` | n/a | yes |
| hub\_config\_image\_digest | n/a | `any` | n/a | yes |
| hub\_frontend\_image\_digest | n/a | `any` | n/a | yes |
| hub\_policy\_image\_digest | n/a | `any` | n/a | yes |
| hub\_saml\_engine\_image\_digest | n/a | `any` | n/a | yes |
| hub\_saml\_proxy\_image\_digest | n/a | `any` | n/a | yes |
| hub\_saml\_soap\_proxy\_image\_digest | n/a | `any` | n/a | yes |
| metadate\_exporter\_image\_digest | n/a | `any` | n/a | yes |
| mgmt\_accessible\_from\_cidrs | n/a | `list` | n/a | yes |
| nginx\_image\_digest | n/a | `any` | n/a | yes |
| prometheus\_image\_digest | n/a | `any` | n/a | yes |
| publically\_accessible\_from\_cidrs | n/a | `list` | n/a | yes |
| signin\_domain | Domain of the frontend of the deployment; will be used for TLS certificates; e.g. www.staging.signin.service.gov.uk | `any` | n/a | yes |
| squid\_image\_digest | n/a | `any` | n/a | yes |
| static\_ingress\_fargate\_image\_digest | n/a | `any` | n/a | yes |
| static\_ingress\_tls\_fargate\_image\_digest | n/a | `any` | n/a | yes |
| tools\_account\_id | AWS account id of the tools account, where docker images will be pulled from | `any` | n/a | yes |
| truststore\_password | n/a | `any` | n/a | yes |
| zendesk\_url | URL for Zendesk | `any` | n/a | yes |
| zendesk\_username | Username (email address) for Zendesk access | `any` | n/a | yes |
| ab\_test\_file | File containing percentage values for variant and control | `string` | `"deactivated_ab_test.yml"` | no |
| certificates\_config\_cache\_expiry | Sets the expiry time of cache for certificates in saml-proxy, saml-engine and saml-soap-proxy | `string` | `"1m"` | no |
| cross\_gov\_ga\_domain\_names | List of (space delimited) domains to automatically enable links and forms for cross-domain analytics | `string` | `"www.gov.uk"` | no |
| cross\_gov\_ga\_tracker\_id | The Google Analytics tracker ID for GOV.UK cross domain analysis | `string` | `""` | no |
| hub\_config\_log\_level | n/a | `string` | `"INFO"` | no |
| hub\_frontend\_log\_level | Log level for Puma and Frontend applications | `string` | `"warn"` | no |
| hub\_policy\_log\_level | n/a | `string` | `"INFO"` | no |
| hub\_saml\_engine\_log\_level | n/a | `string` | `"INFO"` | no |
| hub\_saml\_proxy\_log\_level | n/a | `string` | `"INFO"` | no |
| hub\_saml\_soap\_proxy\_log\_level | n/a | `string` | `"INFO"` | no |
| jvm\_options | n/a | `string` | `"-XX:InitialRAMPercentage=50 -XX:MaxRAMPercentage=80"` | no |
| manage\_metadata | A flag to deploy the metadata and associated infrastructure. Used while moving metadata release to a separate pipeline. Use 1 for true and 0 for false | `number` | `1` | no |
| matomo\_site\_id | Site ID to use for Matomo | `number` | `1` | no |
| metadata\_exporter\_environment | Metadata Exporter environment | `string` | `"development"` | no |
| number\_of\_analytics\_apps | n/a | `number` | `2` | no |
| number\_of\_config\_apps | n/a | `number` | `2` | no |
| number\_of\_egress\_proxy\_apps | n/a | `number` | `2` | no |
| number\_of\_frontend\_apps | n/a | `number` | `2` | no |
| number\_of\_metadata\_apps | n/a | `number` | `2` | no |
| number\_of\_policy\_apps | n/a | `number` | `2` | no |
| number\_of\_prometheus\_apps | n/a | `number` | `3` | no |
| number\_of\_saml\_engine\_apps | n/a | `number` | `2` | no |
| number\_of\_saml\_proxy\_apps | n/a | `number` | `2` | no |
| number\_of\_saml\_soap\_proxy\_apps | n/a | `number` | `2` | no |
| number\_of\_static\_ingress\_apps | n/a | `number` | `2` | no |
| policy\_memory\_limit\_mb | n/a | `number` | `4096` | no |
| prometheus\_volume\_size | n/a | `number` | `100` | no |
| publish\_hub\_config\_enabled | Enable endpoints to expose config service certificates | `string` | `"false"` | no |
| redis\_cache\_size | n/a | `string` | `"cache.t2.small"` | no |
| rp\_truststore\_enabled | The RP truststore should be disabled if any self-service certs will be used by RPs, since we cannot validate the trust chain for self-signed certs | `string` | `"true"` | no |
| saml\_proxy\_memory\_limit\_mb | n/a | `number` | `4096` | no |
| self\_service\_enabled | Enable the use of the Self Service generated metadata | `string` | `"false"` | no |
| throttling\_enabled | Toggles the throttling of IDP traffic on frontend | `string` | `"false"` | no |
| wildcard\_cert\_arn | n/a | `string` | `"ACM cert arn for wildcard of signin_domain"` | no |

## Outputs

| Name | Description |
|------|-------------|
| can\_connect\_to\_container\_vpc\_endpoint | n/a |
| config\_fargate\_v2\_lb\_sg\_id | n/a |
| egress\_eip\_public\_ips | n/a |
| fargate\_ecs\_cluster\_id | n/a |
| hub\_apps\_private\_dns\_namespace\_id | n/a |
| hub\_fargate\_microservice\_security\_group\_id | n/a |
| ingress\_eip\_public\_ips | n/a |
| ingress\_https\_lb\_listener\_arn | n/a |
| ingress\_metadata\_lb\_target\_group\_arn | n/a |
| internal\_subnet\_ids | n/a |
| metadata\_ecs\_execution\_role\_arn | n/a |
| metadata\_task\_security\_group\_id | n/a |
| public\_subnet\_ids | n/a |
| vpc\_id | n/a |
