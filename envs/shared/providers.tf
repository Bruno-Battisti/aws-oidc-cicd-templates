provider "aws" {
  region = var.aws_region

  # Este root NÃO usa autenticação OIDC -- ele é quem PROVISIONA o OIDC
  # Provider e a permissions boundary compartilhada, ou seja, precisa rodar
  # antes de qualquer role existir. Rode-o localmente com credenciais de um
  # operador humano com permissão de IAM admin, ou a partir de um pipeline de
  # bootstrap isolado com suas próprias credenciais de longa duração bem
  # protegidas (idealmente também via OIDC de um provider de identidade
  # diferente, ou MFA + rotação curta).
  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = var.project
    }
  }
}
