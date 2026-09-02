variable "aws_region" {
  description = "Região AWS onde a role de dev é criada."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nome curto do projeto, usado como prefixo em nomes de recursos e no escopo da policy de permissões."
  type        = string
}

variable "owner" {
  description = "Time ou pessoa responsável por este ambiente (tag Owner)."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN do IAM OIDC Provider (output 'oidc_provider_arn' do root envs/shared)."
  type        = string
}

variable "permissions_boundary_arn" {
  description = "ARN da permissions boundary compartilhada (output 'permissions_boundary_arn' do root envs/shared)."
  type        = string
}

variable "github_org" {
  description = "Organização/usuário dono do repositório GitHub que executa os workflows. Ex: minha-org."
  type        = string
}

variable "github_repo" {
  description = "Nome do repositório GitHub (sem o org). Ex: meu-repo."
  type        = string
}

variable "allowed_branch" {
  description = <<-EOT
    Branch a partir do qual o workflow de dev pode assumir esta role
    (usado no claim 'sub' via ref:refs/heads/<allowed_branch>). Fail-safe por
    padrão: só 'main' é confiável até você mudar explicitamente. NUNCA use
    um wildcard "*" aqui -- isso permitiria que qualquer branch (incluindo
    branches de PRs de forks, se o workflow rodar em pull_request_target)
    assumisse a role.
  EOT
  type        = string
  default     = "main"
}

variable "account_id" {
  description = "ID da conta AWS onde os recursos de dev (bucket S3, função Lambda) vivem. Usado para montar ARNs na policy de permissões."
  type        = string
}
