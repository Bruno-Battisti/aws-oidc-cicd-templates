output "role_arn" {
  description = "ARN da role de deploy de prod. Use este valor em 'role-to-assume' no workflow .github/workflows/deploy-prod.yml."
  value       = module.prod_deploy_role.role_arn
}
