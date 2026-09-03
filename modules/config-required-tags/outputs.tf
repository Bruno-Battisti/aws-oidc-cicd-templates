output "config_rule_arn" {
  description = "ARN da AWS Config Rule criada."
  value       = aws_config_config_rule.required_tags.arn
}

output "config_rule_id" {
  description = "ID da AWS Config Rule criada."
  value       = aws_config_config_rule.required_tags.id
}
