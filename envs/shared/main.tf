# -----------------------------------------------------------------------------
# Root "shared" -- recursos de bootstrap, criados UMA VEZ por conta AWS
# -----------------------------------------------------------------------------
# 1. O IAM OIDC Provider do GitHub Actions.
# 2. A permissions boundary compartilhada (ver permissions-boundary.tf).
#
# Os outputs deste root alimentam envs/dev, envs/staging e envs/prod (via
# variável, copiando o valor, ou via "terraform_remote_state" apontando para
# o backend configurado aqui -- ver README.md para o passo a passo).
# -----------------------------------------------------------------------------

locals {
  common_tags = {
    Environment = "shared"
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
  }
}

module "github_oidc_provider" {
  source = "../../modules/oidc-provider"

  tags = local.common_tags
}
