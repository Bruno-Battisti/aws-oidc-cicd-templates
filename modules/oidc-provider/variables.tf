# -----------------------------------------------------------------------------
# Variáveis do módulo oidc-provider
# -----------------------------------------------------------------------------
# Este módulo cria o IAM OIDC Provider do GitHub Actions. Só pode existir UM
# provider por URL em cada conta AWS, então ele deve ser instanciado uma única
# vez por conta (a partir de envs/shared), nunca uma vez por ambiente.
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags aplicadas ao IAM OIDC Provider. Deve conter, no mínimo, as chaves obrigatórias do projeto (Environment, ManagedBy, Project, Owner)."
  type        = map(string)

  validation {
    condition = alltrue([
      for k in ["Environment", "ManagedBy", "Project", "Owner"] : contains(keys(var.tags), k)
    ])
    error_message = "As tags devem incluir obrigatoriamente: Environment, ManagedBy, Project, Owner."
  }
}

variable "thumbprint_list" {
  description = <<-EOT
    Lista de thumbprints (SHA-1) do certificado raiz usado pelo provider OIDC
    do GitHub. A AWS hoje valida a cadeia de CA automaticamente para
    provedores conhecidos como o do GitHub, mas o argumento continua
    obrigatório no schema do recurso aws_iam_openid_connect_provider. Revise
    este valor periodicamente -- veja a documentação da GitHub Actions sobre
    rotação de certificados do OIDC.
  EOT
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea"]
}

variable "client_id_list" {
  description = "Audiences (aud) aceitas pelo provider. sts.amazonaws.com é o valor padrão usado pela action aws-actions/configure-aws-credentials e é o que as trust policies das roles validam via condition aud."
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}
