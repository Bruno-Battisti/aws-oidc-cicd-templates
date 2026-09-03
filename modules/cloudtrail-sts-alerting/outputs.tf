output "sns_topic_arn" {
  description = "ARN do tópico SNS que recebe os alertas. Use para adicionar assinaturas extras (Lambda, SQS, HTTPS) além da assinatura de e-mail opcional deste módulo."
  value       = aws_sns_topic.alerts.arn
}

output "event_rule_arn" {
  description = "ARN da regra do EventBridge que casa eventos de AssumeRoleWithWebIdentity."
  value       = aws_cloudwatch_event_rule.assume_role_web_identity.arn
}
