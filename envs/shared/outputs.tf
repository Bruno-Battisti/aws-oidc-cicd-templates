output "oidc_provider_arn" {
  description = "ARN do IAM OIDC Provider. Copie este valor para a variável oidc_provider_arn de envs/dev, envs/staging e envs/prod (ou consuma via terraform_remote_state)."
  value       = module.github_oidc_provider.arn
}

output "permissions_boundary_arn" {
  description = "ARN da permissions boundary compartilhada. Copie este valor para a variável permissions_boundary_arn de envs/dev, envs/staging e envs/prod."
  value       = aws_iam_policy.permissions_boundary.arn
}
