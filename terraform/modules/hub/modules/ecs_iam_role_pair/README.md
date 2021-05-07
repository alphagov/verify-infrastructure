## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| aws | n/a |

## Modules

No Modules.

## Resources

| Name |
|------|
| [aws_caller_identity](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) |
| [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) |
| [aws_iam_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| deployment | n/a | `any` | n/a | yes |
| service\_name | n/a | `any` | n/a | yes |
| tools\_account\_id | n/a | `any` | n/a | yes |
| image\_name | n/a | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| execution\_role\_arn | n/a |
| execution\_role\_name | n/a |
| task\_role\_arn | n/a |
| task\_role\_name | n/a |
