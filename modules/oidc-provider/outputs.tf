output "arn" {
  description = "ARN do IAM OIDC Provider. Usado como 'Federated principal' nas trust policies das IAM Roles de cada ambiente."
  value       = aws_iam_openid_connect_provider.github_actions.arn
}

output "url" {
  description = "URL do provider OIDC (token.actions.githubusercontent.com), sem o prefixo https://."
  value       = aws_iam_openid_connect_provider.github_actions.url
}
