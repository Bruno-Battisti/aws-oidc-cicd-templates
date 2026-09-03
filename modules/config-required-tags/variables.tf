# -----------------------------------------------------------------------------
# Variáveis do módulo config-required-tags
# -----------------------------------------------------------------------------
# Este módulo cria só a AWS Config Managed Rule "required-tags". Ele NÃO
# cria o Configuration Recorder nem o Delivery Channel -- esses são
# singletons de conta (só pode existir um de cada por região), geralmente já
# ativos via alguma baseline de conta (Control Tower, Security Hub, etc.).
# Aplicar este módulo sem um recorder já ativo falha com
# "InsufficientDeliveryChannelException" -- isso é intencional (fail-fast),
# não um bug do módulo.
# -----------------------------------------------------------------------------

variable "rule_name" {
  description = "Nome da AWS Config Rule."
  type        = string
  default     = "required-tags"
}

variable "tag_keys" {
  description = <<-EOT
    Chaves de tag exigidas em recursos avaliados pela regra gerenciada
    REQUIRED_TAGS. Máximo de 6 (limite da regra gerenciada da AWS). Default
    reflete as mesmas 4 chaves obrigatórias já reforçadas em
    modules/iam-role e modules/oidc-provider (Environment, ManagedBy,
    Project, Owner) -- mas aqui cobrindo compliance contínua (recursos já
    existentes), não só criação.
  EOT
  type        = list(string)
  default     = ["Environment", "ManagedBy", "Project", "Owner"]

  validation {
    condition     = length(var.tag_keys) >= 1 && length(var.tag_keys) <= 6
    error_message = "tag_keys deve ter entre 1 e 6 chaves -- limite da regra gerenciada REQUIRED_TAGS."
  }
}

variable "tags" {
  description = "Tags aplicadas ao próprio recurso da Config Rule."
  type        = map(string)

  validation {
    condition = alltrue([
      for k in ["Environment", "ManagedBy", "Project", "Owner"] : contains(keys(var.tags), k)
    ])
    error_message = "As tags devem incluir obrigatoriamente: Environment, ManagedBy, Project, Owner."
  }
}
