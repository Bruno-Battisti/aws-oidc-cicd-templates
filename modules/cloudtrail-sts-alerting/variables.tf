variable "rule_name" {
  description = "Nome da regra do EventBridge que casa chamadas de AssumeRoleWithWebIdentity."
  type        = string
  default     = "sts-assume-role-with-web-identity-alerts"
}

variable "sns_topic_name" {
  description = "Nome do tópico SNS para onde os alertas são publicados."
  type        = string
  default     = "sts-assume-role-alerts"
}

variable "alert_email" {
  description = "E-mail que recebe os alertas via assinatura SNS. Deixe em branco (\"\") para não criar assinatura -- útil se você preferir assinar o tópico manualmente ou apontar outro consumidor (Lambda, Slack via SNS->Lambda, etc.)."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags aplicadas aos recursos deste módulo."
  type        = map(string)

  validation {
    condition = alltrue([
      for k in ["Environment", "ManagedBy", "Project", "Owner"] : contains(keys(var.tags), k)
    ])
    error_message = "As tags devem incluir obrigatoriamente: Environment, ManagedBy, Project, Owner."
  }
}
