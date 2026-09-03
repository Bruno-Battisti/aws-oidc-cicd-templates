output "oidc_provider_arn" {
  description = "ARN do IAM OIDC Provider. Copie este valor para a variável oidc_provider_arn de envs/dev, envs/staging e envs/prod (ou consuma via terraform_remote_state)."
  value       = module.github_oidc_provider.arn
}

output "permissions_boundary_arn" {
  description = "ARN da permissions boundary compartilhada. Copie este valor para a variável permissions_boundary_arn de envs/dev, envs/staging e envs/prod."
  value       = aws_iam_policy.permissions_boundary.arn
}

output "ci_plan_role_arn" {
  description = "ARN da role de CI plan (somente leitura). Usado em 'role-to-assume' no workflow .github/workflows/terraform-plan.yml e no workflow de verificação de thumbprint."
  value       = module.ci_plan_role.role_arn
}

output "config_required_tags_rule_arn" {
  description = "ARN da AWS Config Rule 'required-tags', se enable_config_required_tags = true. Null caso contrário."
  value       = try(module.config_required_tags[0].config_rule_arn, null)
}

output "sts_alerting_sns_topic_arn" {
  description = "ARN do tópico SNS de alerting de STS, se enable_sts_alerting = true. Null caso contrário."
  value       = try(module.sts_alerting[0].sns_topic_arn, null)
}
