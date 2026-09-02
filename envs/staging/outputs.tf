output "role_arn" {
  description = "ARN da role de deploy de staging. Use este valor em 'role-to-assume' no workflow .github/workflows/deploy-staging.yml."
  value       = module.staging_deploy_role.role_arn
}
