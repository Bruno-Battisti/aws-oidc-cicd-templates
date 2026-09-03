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

# Nível 3, opcional -- ver docs/optional-modules.md. count = 0 por padrão.
module "config_required_tags" {
  source = "../../modules/config-required-tags"
  count  = var.enable_config_required_tags ? 1 : 0

  tag_keys = var.config_required_tags_keys
  tags     = local.common_tags
}

# Nível 3, opcional -- ver docs/optional-modules.md. count = 0 por padrão.
module "sts_alerting" {
  source = "../../modules/cloudtrail-sts-alerting"
  count  = var.enable_sts_alerting ? 1 : 0

  alert_email = var.sts_alert_email
  tags        = local.common_tags
}
