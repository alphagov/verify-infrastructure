## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| ecs_roles | ../ecs_iam_role_pair |  |

## Resources

| Name |
|------|
| [aws_caller_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) |
| [aws_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) |
| [aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) |
| [aws_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) |
| [aws_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) |
| [aws_lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) |
| [aws_route53_record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) |
| [aws_route53_zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone) |
| [aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) |
| [aws_security_group_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) |
| [aws_service_discovery_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| additional\_task\_security\_group\_ids | n/a | `list(string)` | n/a | yes |
| app | n/a | `any` | n/a | yes |
| certificate\_arn | n/a | `any` | n/a | yes |
| container\_name | n/a | `any` | n/a | yes |
| container\_port | n/a | `any` | n/a | yes |
| cpu | n/a | `number` | n/a | yes |
| deployment | n/a | `any` | n/a | yes |
| domain | n/a | `any` | n/a | yes |
| ecs\_cluster\_id | n/a | `string` | n/a | yes |
| lb\_subnets | n/a | `list` | n/a | yes |
| memory | n/a | `number` | n/a | yes |
| service\_discovery\_namespace\_id | n/a | `string` | n/a | yes |
| subnets | n/a | `list(string)` | n/a | yes |
| task\_definition | n/a | `any` | n/a | yes |
| tools\_account\_id | n/a | `any` | n/a | yes |
| vpc\_id | n/a | `any` | n/a | yes |
| deployment\_max\_percent | n/a | `number` | `100` | no |
| deployment\_min\_healthy\_percent | n/a | `number` | `50` | no |
| health\_check\_http\_codes | n/a | `string` | `"200"` | no |
| health\_check\_interval | n/a | `number` | `10` | no |
| health\_check\_path | n/a | `string` | `"/"` | no |
| health\_check\_protocol | n/a | `string` | `"HTTPS"` | no |
| health\_check\_timeout | n/a | `number` | `5` | no |
| image\_name | n/a | `string` | `""` | no |
| number\_of\_tasks | n/a | `number` | `2` | no |

## Outputs

| Name | Description |
|------|-------------|
| execution\_role\_name | n/a |
| lb\_sg\_id | n/a |
| task\_role\_name | n/a |
| task\_sg\_id | n/a |
