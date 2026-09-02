variable "aws_region" {
  description = "Região AWS onde a role de prod é criada."
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
  description = "Organização/usuário dono do repositório GitHub que executa os workflows."
  type        = string
}

variable "github_repo" {
  description = "Nome do repositório GitHub (sem o org)."
  type        = string
}

variable "github_environment" {
  description = <<-EOT
    Nome do GitHub Environment configurado no repositório (Settings >
    Environments) com "Required reviewers" habilitado. É este nome que
    entra no claim 'sub' do token OIDC como
    "repo:<org>/<repo>:environment:<github_environment>", e é essa string
    exata que a trust policy de prod exige (StringEquals, não StringLike --
    prod não aceita nenhum tipo de wildcard). Se o nome do Environment no
    GitHub e este valor não baterem EXATAMENTE, o AssumeRoleWithWebIdentity
    falha -- esse é o comportamento fail-safe desejado.
  EOT
  type        = string
  default     = "production"
}

variable "account_id" {
  description = "ID da conta AWS onde os recursos de prod (bucket S3, função Lambda) vivem. Usado para montar ARNs na policy de permissões."
  type        = string
}
