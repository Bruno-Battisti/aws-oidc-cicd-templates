output "role_arn" {
  description = "ARN da IAM Role criada. É este valor que vai em 'role-to-assume' no workflow do GitHub Actions (aws-actions/configure-aws-credentials)."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Nome da IAM Role criada."
  value       = aws_iam_role.this.name
}
