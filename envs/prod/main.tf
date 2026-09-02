locals {
  environment = "prod"
  role_name   = "${var.project}-${local.environment}-deploy"

  common_tags = {
    Environment = local.environment
    ManagedBy   = "terraform"
    Project     = var.project
    Owner       = var.owner
  }
}

module "prod_deploy_role" {
  source = "../../modules/iam-role"

  environment = local.environment
  role_name   = local.role_name

  trust_policy_json       = data.aws_iam_policy_document.trust.json
  permissions_policy_json = data.aws_iam_policy_document.permissions.json

  permissions_boundary_arn = var.permissions_boundary_arn

  # Sessão mais curta em prod: reduz ainda mais a janela de exposição das
  # credenciais temporárias emitidas para o runner do GitHub Actions.
  max_session_duration = 1800

  tags = local.common_tags
}
