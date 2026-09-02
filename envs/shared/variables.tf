variable "aws_region" {
  description = "Região AWS onde os recursos globais/de bootstrap (OIDC provider, permissions boundary) são criados. IAM é um serviço global, mas a API precisa ser chamada a partir de uma região."
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nome curto do projeto, usado como prefixo em nomes de recursos e como tag Project. Ex: myproject."
  type        = string
}

variable "owner" {
  description = "Time ou pessoa responsável pelos recursos deste projeto (tag Owner). Ex: platform-team."
  type        = string
}

variable "allowed_regions" {
  description = "Regiões AWS nas quais as roles de CI/CD deste projeto podem operar. Usada na condition da permissions boundary (DenyOutsideAllowedRegions) para reduzir o risco de recursos criados silenciosamente em regiões não monitoradas."
  type        = list(string)
  default     = ["us-east-1", "us-east-2"]
}
