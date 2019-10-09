output "rails_secet_key_base" {
  value     = aws_ssm_parameter.rails_secret_key_base.value
  sensitive = true
}
