output "role_arn" {
  description = "ARN da role de deploy de dev. Use este valor em 'role-to-assume' no workflow .github/workflows/deploy-dev.yml."
  value       = module.dev_deploy_role.role_arn
}
