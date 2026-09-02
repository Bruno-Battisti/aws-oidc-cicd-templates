# -----------------------------------------------------------------------------
# Variáveis do módulo iam-role
# -----------------------------------------------------------------------------
# Este módulo é intencionalmente "burro": ele não decide trust policy nem
# policy de permissões, apenas recebe ambos prontos (JSON) via variável.
# Isso obriga quem consome o módulo (envs/dev, envs/staging, envs/prod) a
# declarar explicitamente as condições de sub/aud e o escopo de permissões
# do seu próprio ambiente, em vez de herdar um comportamento implícito.
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Nome do ambiente ao qual esta role pertence (dev, staging ou prod). Usado para nomear recursos e como trilha de auditoria em logs/CloudTrail."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment deve ser um de: dev, staging, prod."
  }
}

variable "role_name" {
  description = "Nome da IAM Role. Recomenda-se incluir projeto e ambiente no nome, ex: myproject-prod-deploy, para facilitar auditoria e permissions boundaries baseadas em prefixo de nome."
  type        = string
}

variable "trust_policy_json" {
  description = <<-EOT
    Documento JSON da assume-role policy (trust policy). Deve ser o mais
    restritivo possível: restringir por 'sub' (repo/branch ou repo/environment)
    e por 'aud' (token.actions.githubusercontent.com:aud = sts.amazonaws.com).
    Gerado normalmente via data "aws_iam_policy_document" no root que
    consome este módulo (ver envs/dev/trust-policy.tf, envs/prod/trust-policy.tf).
  EOT
  type        = string
}

variable "permissions_policy_json" {
  description = "Documento JSON da policy IN-LINE de permissões (least privilege) anexada à role. Define o que a role PODE fazer, dentro do teto imposto pelo permissions boundary."
  type        = string
}

variable "managed_policy_arns" {
  description = "Lista opcional de ARNs de managed policies adicionais a anexar à role (ex: policies gerenciadas pela AWS). Use com moderação -- prefira a policy inline para manter o escopo explícito, versionado e auditável no mesmo lugar que a role."
  type        = list(string)
  default     = []
}

variable "permissions_boundary_arn" {
  description = <<-EOT
    ARN da permissions boundary aplicada à role. É a rede de segurança que
    limita o blast radius mesmo que 'permissions_policy_json' tenha um erro
    de configuração (ex: um "Resource": "*" esquecido em um statement Allow).
    Este módulo não permite criar uma role sem boundary -- não há valor
    default, a variável é obrigatória.
  EOT
  type        = string
}

variable "max_session_duration" {
  description = "Duração máxima (segundos) da sessão assumida via STS. Mantenha baixo para reduzir a janela de exposição de credenciais temporárias emitidas para o runner do GitHub Actions."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 900 && var.max_session_duration <= 3600
    error_message = "max_session_duration deve estar entre 900 (15 min) e 3600 (1h). Workflows de CI raramente precisam de mais que isso."
  }
}

variable "tags" {
  description = "Tags obrigatórias aplicadas à role: Environment, ManagedBy, Project, Owner (mais quaisquer tags extras opcionais)."
  type        = map(string)

  validation {
    condition = alltrue([
      for k in ["Environment", "ManagedBy", "Project", "Owner"] : contains(keys(var.tags), k)
    ])
    error_message = "As tags devem incluir obrigatoriamente: Environment, ManagedBy, Project, Owner."
  }
}
